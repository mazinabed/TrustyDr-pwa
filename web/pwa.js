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

// --- 2. Update Detection ---
// The banner appears ONLY when version.json confirms the deployed version
// differs from the version active when this page loaded.
//
// controllerchange triggers an immediate version check but never shows the
// banner directly. This eliminates false positives from:
//   - DevTools "Update on reload"
//   - SW re-claim events after page reload
//   - Any other controllerchange noise
//
// _notified ensures only one pwa_update_available event is dispatched
// regardless of how many detection paths fire.
(function () {
  var _notified = false;
  var _baseVersion = null;
  var _POLL_MS = 60000; // polling interval — change this value to adjust

  function _notifyUpdate() {
    if (_notified) return;
    _notified = true;
    // Persist flag so Dart can catch it if event fired before BottomBar mounted.
    window.__pwaUpdateAvailable = true;
    window.dispatchEvent(new Event('pwa_update_available'));
  }

  function _versionKey(json) {
    return json.version + '+' + json.build_number;
  }

  function _checkVersion() {
    fetch('/version.json?t=' + Date.now(), {
      cache: 'no-store',
      headers: { 'pragma': 'no-cache', 'cache-control': 'no-cache' }
    })
      .then(function (r) { return r.json(); })
      .then(function (json) {
        var key = _versionKey(json);
        if (_baseVersion === null) {
          _baseVersion = key; // first call — establish baseline, never notify
        } else if (key !== _baseVersion) {
          _notifyUpdate();
        }
      })
      .catch(function () {
        // Network error or parse failure — silently skip this tick.
      });
  }

  // Layer 1: controllerchange → version check only.
  // Banner fires only if version.json confirms a real deployment, not
  // just because the SW controller changed.
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('controllerchange', function () {
      _checkVersion();
    });
  }

  // Layer 2: Establish baseline immediately on page load, then poll.
  // No startup delay — baseline must be set before controllerchange
  // could fire to minimise the race window.
  _checkVersion();
  setInterval(_checkVersion, _POLL_MS);
})();
