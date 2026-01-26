let deferredPrompt = null;

// --- 1. Installation Logic (Existing) ---
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

// --- 2. Update Detection Logic (New) ---
