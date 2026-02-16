// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

String getCurrentPath() {
  return html.window.location.pathname ?? '';
}
