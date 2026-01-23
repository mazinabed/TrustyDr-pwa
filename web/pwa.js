let deferredPrompt = null;

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
