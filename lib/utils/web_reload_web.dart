import 'dart:html' as html;
import 'dart:js' as js;

void reloadPage() {
  html.window.location.reload();
}

void listenForPwaUpdate(void Function() onUpdate) {
  html.window.addEventListener('pwa_update_available', (_) {
    onUpdate();
  });
}

bool isPwaUpdateAvailable() {
  return js.context['__pwaUpdateAvailable'] == true;
}
