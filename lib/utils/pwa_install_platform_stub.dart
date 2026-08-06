// Non-web (VM/mobile/desktop/test) implementation — see
// pwa_install_platform.dart's own header comment. TrustyInstallBanner
// already gates its own visibility on kIsWeb before any of these are
// meaningfully consulted, so these no-op/false defaults are never reached
// on a real non-web run either; they exist purely so the VM test platform
// (which has neither dart:html nor a browser) has something to compile
// against.
bool isStandalone() => false;

void listenForInstallAvailable(void Function() onAvailable) {}

bool canInstall() => false;

Future<void> promptInstall() async {}
