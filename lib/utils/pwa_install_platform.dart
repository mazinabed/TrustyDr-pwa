// Platform abstraction for PWA install-banner support (2026-08-08) — same
// conditional-export pattern already established by web_location.dart/
// web_reload.dart in this directory. Isolates dart:html/dart:js_interop
// (only available on the web platform) behind a plain Dart API so
// pwa_install_banner.dart, and everything that transitively imports it
// (home.dart -> bottom_bar.dart -> screens.dart -> login.dart ->
// marketplace_widgets.dart), compiles on the VM test platform used by
// plain `flutter test` — that transitive dart:html import was previously
// the ONLY thing blocking widget tests for MarketplaceStoreHeader/
// MarketplaceStorePage. No runtime behavior change: the web
// implementation is byte-for-byte the same dart:html/js_interop calls the
// widget used to make directly.
export 'pwa_install_platform_stub.dart'
    if (dart.library.html) 'pwa_install_platform_web.dart';
