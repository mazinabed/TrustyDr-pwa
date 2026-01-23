Architecture locked:
- Firebase init happens in SplashScreen (must remain there)
- Firestore reads must happen through providers/services only
- No city → Stream.empty (no queries)
Current focus: P0 cost leaks (#1 provider guard)
