import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:singbox_client/models/app_settings.dart';
import 'package:singbox_client/models/node_config.dart';
import 'package:singbox_client/services/config_builder.dart';
import 'package:singbox_client/services/xray_config_parser.dart';

/// Эталонные снимки sing-box-конфигов, снятые ДО выноса конвертера из парсера.
/// Их задача — доказать, что рефакторинг конвертера не изменил ни одного
/// существующего конфига.
///
/// Эталон `_goldenNaiveTun` пересняли ровно один раз — когда в TUN появились
/// bypass-правила (`process_name: xray`, серверный IP, приватные сети). Это
/// намеренное изменение поведения из задачи про второй движок, а не регрессия.
void main() {
  const builder = ConfigBuilder(localPort: 2080);

  String canonical(Map<String, dynamic> cfg) =>
      const JsonEncoder.withIndent('  ').convert(cfg);

  test('golden: vless+reality из share-параметров', () {
    const node = NodeConfig(
      name: 'A', protocol: NodeProtocol.vless, host: 'example.com', port: 443,
      params: {
        'uuid': 'uid', 'security': 'reality', 'pbk': 'KEY',
        'sni': 'www.apple.com', 'sid': 'ab', 'fp': 'chrome',
        'flow': 'xtls-rprx-vision',
      },
    );
    expect(canonical(builder.build(node)), _goldenVlessProxy);
  });

  test('golden: naive в режиме TUN', () {
    const node = NodeConfig(
      name: 'B', protocol: NodeProtocol.naive, host: 'h.example', port: 443,
      params: {'username': 'u', 'password': 'p'},
    );
    expect(
      canonical(builder.build(node, mode: TunnelMode.tun, serverIp: '1.2.3.4')),
      _goldenNaiveTun,
    );
  });

  test('golden: hysteria2 из Xray-подписки', () {
    const json = '''
[{"outbounds":[
  {"tag":"proxy","protocol":"hysteria",
   "settings":{"address":"193.233.133.11","port":443,"version":2},
   "streamSettings":{"network":"hysteria",
     "hysteriaSettings":{"version":2,"auth":"AUTH"},
     "security":"tls",
     "tlsSettings":{"serverName":"cdn1.example","fingerprint":"chrome","alpn":["h3"]}}}],
  "remarks":"FR"}]''';
    final node = parseXrayConfigs(json)!.single;
    expect(canonical(builder.build(node)), _goldenHysteriaFromSub);
  });
}

const _goldenVlessProxy = r'''{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "type": "https",
        "tag": "proxy-dns",
        "server": "1.1.1.1",
        "detour": "proxy",
        "domain_resolver": "direct-dns"
      },
      {
        "type": "https",
        "tag": "direct-dns",
        "server": "77.88.8.8",
        "tls": {
          "server_name": "common.dot.dns.yandex.net"
        }
      }
    ],
    "final": "proxy-dns",
    "strategy": "ipv4_only"
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 2080
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "proxy",
      "server": "example.com",
      "server_port": 443,
      "uuid": "uid",
      "tls": {
        "enabled": true,
        "server_name": "www.apple.com",
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        },
        "reality": {
          "enabled": true,
          "public_key": "KEY",
          "short_id": "ab"
        }
      },
      "flow": "xtls-rprx-vision",
      "domain_resolver": "direct-dns"
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "rules": [
      {
        "ip_cidr": [
          "77.88.8.8/32"
        ],
        "outbound": "direct"
      }
    ],
    "final": "proxy",
    "default_domain_resolver": "proxy-dns"
  }
}''';

const _goldenNaiveTun = r'''{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "type": "https",
        "tag": "proxy-dns",
        "server": "1.1.1.1",
        "detour": "proxy",
        "domain_resolver": "direct-dns"
      },
      {
        "type": "https",
        "tag": "direct-dns",
        "server": "77.88.8.8",
        "tls": {
          "server_name": "common.dot.dns.yandex.net"
        }
      }
    ],
    "final": "proxy-dns",
    "strategy": "ipv4_only"
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "address": [
        "198.18.0.1/30",
        "fdfe:dcba:9876::1/126"
      ],
      "auto_route": true,
      "strict_route": false,
      "mtu": 4064,
      "stack": "gvisor"
    }
  ],
  "outbounds": [
    {
      "type": "naive",
      "tag": "proxy",
      "server": "h.example",
      "server_port": 443,
      "username": "u",
      "password": "p",
      "tls": {
        "enabled": true,
        "server_name": "h.example"
      },
      "domain_resolver": "direct-dns"
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "rules": [
      {
        "action": "hijack-dns",
        "port": 53
      },
      {
        "ip_version": 6,
        "action": "reject"
      },
      {
        "network": "udp",
        "port": 443,
        "action": "reject"
      },
      {
        "port": [
          80,
          443
        ],
        "action": "sniff"
      },
      {
        "ip_cidr": [
          "77.88.8.8/32"
        ],
        "outbound": "direct"
      },
      {
        "process_name": [
          "xray"
        ],
        "outbound": "direct"
      },
      {
        "ip_cidr": [
          "1.2.3.4/32"
        ],
        "outbound": "direct"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      }
    ],
    "final": "proxy",
    "auto_detect_interface": true,
    "default_domain_resolver": "proxy-dns"
  }
}''';

const _goldenHysteriaFromSub = r'''{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "type": "https",
        "tag": "proxy-dns",
        "server": "1.1.1.1",
        "detour": "proxy",
        "domain_resolver": "direct-dns"
      },
      {
        "type": "https",
        "tag": "direct-dns",
        "server": "77.88.8.8",
        "tls": {
          "server_name": "common.dot.dns.yandex.net"
        }
      }
    ],
    "final": "proxy-dns",
    "strategy": "ipv4_only"
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 2080
    }
  ],
  "outbounds": [
    {
      "type": "hysteria2",
      "tag": "proxy",
      "server": "193.233.133.11",
      "server_port": 443,
      "password": "AUTH",
      "tls": {
        "enabled": true,
        "server_name": "cdn1.example",
        "alpn": [
          "h3"
        ],
        "utls": {
          "enabled": true,
          "fingerprint": "chrome"
        }
      },
      "domain_resolver": "direct-dns"
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "rules": [
      {
        "ip_cidr": [
          "77.88.8.8/32"
        ],
        "outbound": "direct"
      }
    ],
    "final": "proxy",
    "default_domain_resolver": "proxy-dns"
  }
}''';
