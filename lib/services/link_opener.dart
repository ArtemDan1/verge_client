import 'package:url_launcher/url_launcher.dart';

/// Открывает ссылку во внешнем браузере. Обёртка нужна, чтобы UI не зависел
/// от пакета напрямую и её можно было подменить в тестах.
Future<bool> openLink(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
