import 'dart:html' as html;

void reloadPage() {
  html.window.location.reload();
}

void listenForPwaUpdate(void Function() onUpdate) {
  html.window.addEventListener('pwa_update_available', (_) {
    onUpdate();
  });
}
