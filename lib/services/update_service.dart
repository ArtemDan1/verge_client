import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';
import 'trusted_roots.dart';
import 'version_compare.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.pkgUrl,
    required this.releaseUrl,
  });
  final String version;
  final String pkgUrl;
  final String releaseUrl;
}

/// Проверка обновлений через GitHub Releases и загрузка .pkg-ассета.
class UpdateService {
  UpdateService({
    http.Client? client,
    this.owner = 'ArtemDan1',
    this.repo = 'verge_client',
    String? assetSuffix,
    String? downloadFileName,
  })  : _injectedClient = client,
        // Windows получает инсталлятор Inno Setup, macOS — .pkg.
        assetSuffix =
            assetSuffix ?? (Platform.isWindows ? '-setup.exe' : '.pkg'),
        downloadFileName = downloadFileName ??
            (Platform.isWindows
                ? 'Verge-update-setup.exe'
                : 'SingboxFlutter-update.pkg');

  final http.Client? _injectedClient;
  http.Client? _defaultClient;
  final String owner;
  final String repo;
  final String assetSuffix;
  final String downloadFileName;

  /// Клиент, которым ходим на GitHub.
  ///
  /// На Windows — с бандленными корневыми сертификатами: системное хранилище
  /// там наполняется лениво и на api.github.com спотыкается, см. [TrustedRoots].
  /// В тестах клиент подставляется через конструктор, и эта ветка не работает.
  Future<http.Client> _client() async {
    final injected = _injectedClient;
    if (injected != null) return injected;
    final cached = _defaultClient;
    if (cached != null) return cached;
    final hc = await TrustedRoots.httpClient();
    final created = hc != null ? IOClient(hc) : http.Client();
    _defaultClient = created;
    return created;
  }

  Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    final uri =
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
    final client = await _client();
    final res = await client
        .get(uri, headers: const {'Accept': 'application/vnd.github+json'});
    // 404 = в репозитории нет опубликованных релизов (черновики/pre-release не
    // считаются) → обновлений нет, это не ошибка.
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('GitHub API ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final tag = (json['tag_name'] as String?) ?? '';
    final assets =
        ((json['assets'] as List?) ?? const []).cast<Map<String, dynamic>>();
    final pkg = assets.firstWhere(
      (a) =>
          (a['name'] as String?)
              ?.toLowerCase()
              .endsWith(assetSuffix.toLowerCase()) ==
          true,
      orElse: () => const <String, dynamic>{},
    );
    final pkgUrl = pkg['browser_download_url'] as String?;
    if (pkgUrl == null) return null;
    if (compareVersions(tag, currentVersion) <= 0) return null;
    return UpdateInfo(
      version: tag,
      pkgUrl: pkgUrl,
      releaseUrl: (json['html_url'] as String?) ?? '',
    );
  }

  /// Качает .pkg в [targetDir] (по умолчанию системная temp). Возвращает путь.
  Future<String> downloadPkg(String url,
      {void Function(double progress)? onProgress, Directory? targetDir}) async {
    final client = await _client();
    final resp = await client.send(http.Request('GET', Uri.parse(url)));
    if (resp.statusCode != 200) {
      throw Exception('download ${resp.statusCode}');
    }
    final total = resp.contentLength ?? 0;
    final dir = targetDir ?? await getTemporaryDirectory();
    // getTemporaryDirectory() на macOS отдаёт ~/Library/Caches/<bundle-id> и не
    // создаёт её: вне сэндбокса папки может не быть, и openWrite падает
    // PathNotFoundException.
    await dir.create(recursive: true);
    final file = File('${dir.path}/$downloadFileName');
    final sink = file.openWrite();
    var received = 0;
    await for (final chunk in resp.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0 && onProgress != null) onProgress(received / total);
    }
    await sink.close();
    return file.path;
  }
}
