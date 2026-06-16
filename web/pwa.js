let deferredPrompt = null;

// --- 1. Installation Logic ---
window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;
  window.dispatchEvent(new Event('pwa-install-available'));
});

window.trustyDrPromptInstall = async () => {
  if (!deferredPrompt) return false;
  deferredPrompt.prompt();
  const { outcome } = await deferredPrompt.userChoice;
  deferredPrompt = null;
  return outcome === 'accepted';
};

window.trustyDrCanInstall = () => !!deferredPrompt;

// --- 2. Update Detection (shared notify gate) ---
// Both Layer 1 (controllerchange) and Layer 2 (version polling) funnel through
// _notifyUpdate(). The _notified flag ensures only one pwa_update_available
// event is ever dispatched, so the banner cannot appear twice.
(function () {
  var _notified = false;

  function _notifyUpdate() {
    if (_notified) return;
    _notified = true;
    // Persist the flag so Dart can check it after BottomBar mounts,
    // even if the event already fired before the listener was registered.
    window.__pwaUpdateAvailable = true;
    window.dispatchEvent(new Event('pwa_update_available'));
  }

  // Layer 1: Service worker controller change.
  // Flutter's flutter_service_worker.js calls skipWaiting() + clients.claim(),
  // so controllerchange fires when a new SW activates. Works reliably when the
  // SW update cycle completes while the tab is open.
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('controllerchange', function () {
      _notifyUpdate();
    });
  }

  // Layer 2: version.json polling (backup detection).
  // Catches cases where controllerchange never fires (tab opened before deploy,
  // SW already at latest, or browser SW update quirks).
  // Poll interval: 60 seconds. Change _POLL_MS to adjust after verification.
  var _POLL_MS = 60000;
  var _baseVersion = null; // set after first successful fetch

  function _versionKey(json) {
    // Use build_number + version as the compound identity.
    // build_number increments on every `flutter build web`.
    return json.version + '+' + json.build_number;
  }

  function _fetchVersion() {
    fetch('/version.json?t=' + Date.now(), {
      cache: 'no-store',
      headers: { 'pragma': 'no-cache', 'cache-control': 'no-cache' }
    })
      .then(function (r) { return r.json(); })
      .then(function (json) {
        var key = _versionKey(json);
        if (_baseVersion === null) {
          _baseVersion = key;
        } else if (key !== _baseVersion) {
          _notifyUpdate();
        }
      })
      .catch(function () {
        // Network error — silently skip this tick.
      });
  }

  // Start polling after a short delay so Flutter finishes booting first.
  setTimeout(function () {
    _fetchVersion(); // establish baseline
    setInterval(_fetchVersion, _POLL_MS);
  }, 5000);
})();
