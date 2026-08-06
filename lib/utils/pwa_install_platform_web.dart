// Web implementation — see pwa_install_platform.dart's own header
// comment. Every call here is byte-for-byte the same dart:html/js_interop
// code TrustyInstallBanner used to make directly before this split; no
// runtime behavior change, only where the platform-specific code lives.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_interop';

@JS('trustyDrCanInstall')
external bool _canInstallJS();

@JS('trustyDrPromptInstall')
external JSPromise _promptInstallJS();

bool isStandalone() =>
    html.window.matchMedia('(display-mode: standalone)').matches;

void listenForInstallAvailable(void Function() onAvailable) {
  html.window.addEventListener('pwa-install-available', (_) => onAvailable());
}

bool canInstall() => _canInstallJS();

Future<void> promptInstall() async {
  await _promptInstallJS().toDart;
}
