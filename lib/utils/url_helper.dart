import 'dart:js_interop';
import 'package:web/web.dart' as web;

void openUrl(String url) {
  web.window.open(url, '_blank');
}
