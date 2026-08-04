import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../app/app_controller.dart';
import '../models/node_config.dart';
import '../services/node_editor.dart';

enum _Tab { form, json }

/// Диалог редактирования ноды: общая форма для обеих схем или сырой JSON.
Future<void> showEditNodeDialog(
  BuildContext context,
  AppController controller,
  String profileId,
  int index,
  NodeConfig node,
) async {
  await showShadDialog(
    context: context,
    builder: (ctx) => _EditNodeDialog(
      controller: controller,
      profileId: profileId,
      index: index,
      node: node,
    ),
  );
}

class _EditNodeDialog extends StatefulWidget {
  const _EditNodeDialog({
    required this.controller,
    required this.profileId,
    required this.index,
    required this.node,
  });

  final AppController controller;
  final String profileId;
  final int index;
  final NodeConfig node;

  @override
  State<_EditNodeDialog> createState() => _EditNodeDialogState();
}

class _EditNodeDialogState extends State<_EditNodeDialog> {
  late NodeDraft _draft;

  /// Нода в её текущем состоянии редактирования — база, поверх которой
  /// применяются правки формы. Не widget.node: после правки на вкладке JSON
  /// база — уже отредактированный outbound, иначе поля, которых нет в форме,
  /// потерялись бы при сохранении.
  late NodeConfig _current;

  _Tab _tab = _Tab.form;
  String? _jsonError;

  final _nameCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _uuidCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _flowCtrl = TextEditingController();
  final _sniCtrl = TextEditingController();
  final _fingerprintCtrl = TextEditingController();
  final _publicKeyCtrl = TextEditingController();
  final _shortIdCtrl = TextEditingController();
  final _pathCtrl = TextEditingController();
  final _hostHeaderCtrl = TextEditingController();
  final _jsonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _current = widget.node;
    _draft = draftFromNode(_current);
    _fillControllersFromDraft();
    final raw = widget.node.rawOutbound;
    if (raw != null) {
      _jsonCtrl.text = const JsonEncoder.withIndent('  ').convert(raw);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _uuidCtrl.dispose();
    _passwordCtrl.dispose();
    _flowCtrl.dispose();
    _sniCtrl.dispose();
    _fingerprintCtrl.dispose();
    _publicKeyCtrl.dispose();
    _shortIdCtrl.dispose();
    _pathCtrl.dispose();
    _hostHeaderCtrl.dispose();
    _jsonCtrl.dispose();
    super.dispose();
  }

  // Набор полей формы идёт от _current: на вкладке JSON протокол могли
  // поменять, и форма должна показать поля нового протокола.
  bool get _needsUuid =>
      const {'vless', 'vmess'}.contains(_current.displayProtocol);

  bool get _needsPassword =>
      const {'trojan', 'ss', 'hysteria2', 'naive'}
          .contains(_current.displayProtocol);

  bool get _needsTls => _current.displayProtocol != 'ss';

  void _fillControllersFromDraft() {
    _nameCtrl.text = _draft.name;
    _hostCtrl.text = _draft.host;
    _portCtrl.text = '${_draft.port}';
    _uuidCtrl.text = _draft.uuid ?? '';
    _passwordCtrl.text = _draft.password ?? '';
    _flowCtrl.text = _draft.flow ?? '';
    _sniCtrl.text = _draft.sni ?? '';
    _fingerprintCtrl.text = _draft.fingerprint ?? '';
    _publicKeyCtrl.text = _draft.publicKey ?? '';
    _shortIdCtrl.text = _draft.shortId ?? '';
    _pathCtrl.text = _draft.path ?? '';
    _hostHeaderCtrl.text = _draft.hostHeader ?? '';
  }

  NodeDraft _readDraftFromControllers() {
    return _draft
      ..name = _nameCtrl.text
      ..host = _hostCtrl.text
      ..port = int.tryParse(_portCtrl.text.trim()) ?? _draft.port
      ..uuid = _uuidCtrl.text
      ..password = _passwordCtrl.text
      ..flow = _flowCtrl.text
      ..sni = _sniCtrl.text
      ..fingerprint = _fingerprintCtrl.text
      ..publicKey = _publicKeyCtrl.text
      ..shortId = _shortIdCtrl.text
      ..path = _pathCtrl.text
      ..hostHeader = _hostHeaderCtrl.text;
  }

  void _syncFormToJson() {
    _current = applyDraft(_current, _readDraftFromControllers());
    _jsonCtrl.text =
        const JsonEncoder.withIndent('  ').convert(_current.rawOutbound);
    setState(() => _jsonError = null);
  }

  bool _syncJsonToForm() {
    final parsed = _parseJson();
    if (parsed == null) return false;
    setState(() {
      _current = _nodeWithRaw(parsed);
      _draft = draftFromNode(_current);
      _fillControllersFromDraft();
    });
    return true;
  }

  Map<String, dynamic>? _parseJson() {
    try {
      final decoded = jsonDecode(_jsonCtrl.text);
      if (decoded is! Map) {
        setState(() => _jsonError = 'Ожидается JSON-объект');
        return null;
      }
      setState(() => _jsonError = null);
      return decoded.cast<String, dynamic>();
    } on FormatException catch (e) {
      setState(() => _jsonError = e.message);
      return null;
    }
  }

  NodeConfig _nodeWithRaw(Map<String, dynamic> raw) => NodeConfig(
        name: _current.name,
        protocol: _current.protocol,
        host: _current.host,
        port: _current.port,
        params: _current.params,
        rawSchema: _current.rawSchema,
        rawOutbound: raw,
      );

  void _setTab(_Tab tab) {
    if (tab == _tab) return;
    if (_tab == _Tab.form) {
      _syncFormToJson();
    } else {
      if (!_syncJsonToForm()) return;
    }
    setState(() => _tab = tab);
  }

  void _save() {
    final NodeConfig result;
    if (_tab == _Tab.json) {
      final parsed = _parseJson();
      if (parsed == null) return;
      result = _nodeWithRaw(parsed);
    } else {
      result = applyDraft(_current, _readDraftFromControllers());
    }
    widget.controller.updateNode(widget.profileId, widget.index, result);
    Navigator.of(context).pop();
  }

  void _setTransport(String? value) {
    setState(() => _draft.transport = value);
  }

  void _setSecurity(String? value) {
    setState(() => _draft.security = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final raw = widget.node.rawOutbound;
    final showJsonTab = raw != null;
    final hasError = _tab == _Tab.json && _jsonError != null;

    Widget field(String label, TextEditingController controller,
        {TextInputType? keyboardType, int maxLines = 1}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.muted),
          const SizedBox(height: 4),
          ShadInput(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    Widget select<T>(
      String label,
      T value,
      List<({T value, String label})> items,
      ValueChanged<T> onChanged,
    ) {
      final opts = [
        for (final item in items)
          ShadOption(value: item.value, child: Text(item.label)),
      ];
      String labelFor(T v) {
        for (final item in items) {
          if (item.value == v) return item.label;
        }
        return '$v';
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.muted),
          const SizedBox(height: 4),
          ShadSelect<T>(
            key: ValueKey('$label-$value'),
            initialValue: value,
            options: opts,
            selectedOptionBuilder: (ctx, v) => Text(labelFor(v)),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    final formChildren = <Widget>[
      field('Имя', _nameCtrl),
      Row(
        children: [
          Expanded(flex: 3, child: field('Хост', _hostCtrl)),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: field('Порт', _portCtrl,
                keyboardType: TextInputType.number),
          ),
        ],
      ),
      if (_needsUuid) ...[
        field('UUID', _uuidCtrl),
        field('Flow', _flowCtrl),
      ],
      if (_needsPassword) field('Пароль', _passwordCtrl),
      if (_needsTls) ...[
        select<String?>(
          'Шифрование',
          _draft.security,
          [
            (value: null, label: 'Нет'),
            (value: 'tls', label: 'TLS'),
            (value: 'reality', label: 'Reality'),
          ],
          _setSecurity,
        ),
        if (_draft.security != null) ...[
          field('SNI', _sniCtrl),
          field('Fingerprint', _fingerprintCtrl),
          if (_draft.security == 'reality') ...[
            field('Public key', _publicKeyCtrl),
            field('Short ID', _shortIdCtrl),
          ],
        ],
      ],
      select<String?>(
        'Транспорт',
        _draft.transport,
        [
          (value: null, label: 'Нет'),
          (value: 'ws', label: 'WebSocket'),
          (value: 'grpc', label: 'gRPC'),
          (value: 'xhttp', label: 'XHTTP'),
          (value: 'http', label: 'HTTP'),
        ],
        _setTransport,
      ),
      if (_draft.transport != null && _draft.transport!.isNotEmpty) ...[
        field('Path', _pathCtrl),
        field('Host-заголовок', _hostHeaderCtrl),
      ],
    ];

    return ShadDialog(
      title: const Text('Редактировать ноду'),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ShadButton(
          onPressed: hasError ? null : _save,
          child: const Text('Сохранить'),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.node.rawSchema == RawSchema.xray
                    ? 'Схема: Xray'
                    : 'Схема: sing-box',
                style: theme.textTheme.muted,
              ),
              const SizedBox(height: 12),
              if (showJsonTab) ...[
                ShadTabs<_Tab>(
                  value: _tab,
                  onChanged: _setTab,
                  tabs: [
                    ShadTab(value: _Tab.form, child: const Text('Форма')),
                    ShadTab(value: _Tab.json, child: const Text('JSON')),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (_tab == _Tab.form)
                ...formChildren
              else ...[
                ShadInput(
                  controller: _jsonCtrl,
                  maxLines: 16,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                if (_jsonError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _jsonError!,
                    style: TextStyle(color: theme.colorScheme.destructive),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Text(
                'Изменения будут перезаписаны при обновлении подписки',
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
