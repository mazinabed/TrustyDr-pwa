# MyDoctor – Production Hardening

## Non-negotiable Guardrails (MUST)
- No city selected → NO Firestore reads (Stream.empty / do not build query)
- Every list query must be scoped by: status + province + city (when applicable)
- Any potentially large query must use limit()
- No Firestore queries inside UI widgets directly (use providers/services)
- No anonymous/auto-auth unless explicitly intended (define policy)

## P0 – Cost Leaks (Fix first)
1) Provider-level Firestore guard (NO city → NO reads) — In progress
   - Files: app_location_provider.dart, stream providers
   - Test: open app without city → 0 Firestore reads

2) Search screen audit (debounce + limit + require city) — Open
   - Test: typing doesn’t trigger uncontrolled reads

3) Specialty bar stream optimization (cache/limit/global strategy) — Open

4) Appointments streams monitoring (limits/indexes) — Open

5) Firestore composite index hygiene — Open

## P0 – Security
- Firestore Rules audit — Open
- Appointment write validation — Open
- Doctor self-access validation — Open

## P1 – Reliability / On-call readiness
- Crashlytics enabled — Open
- Performance monitoring enabled — Open
- Structured logs for key flows — Open

## P1 – Performance
- Images caching policy — Open
- List rendering optimization — Open
