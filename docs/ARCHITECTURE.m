# TrustyDr — Architecture (System Map)

## Apps
- Patient App: Flutter (Android/iOS)
- Doctor Portal: Flutter Web
- Admin Portal: Flutter Web

## Backend
- Firebase Auth (phone-based; guest usage allowed only if explicitly designed)
- Firestore (city/province-scoped reads; providers own all reads)
- Cloud Functions (payments, cleanup jobs, admin tasks)
- Storage (optional media; use retention policy if enabled)

## Core Data Collections (high level)
- doctors (registered providers)
- google_doctors (google placeholders)
- specialties
- users / profiles
- appointments
- (optional later) chats, chat_messages, chat_media

## Location Model
- Location is selected by user (province + city)
- appLocationProvider is the single source of truth
- Every doctor/clinic query is scoped by the selected location

## UI Structure
- BottomBar uses IndexedStack to keep tabs alive
- SpecialityScreen shows:
  - specialties bar
  - registered doctors list (filtered locally for search)
  - google clinics section when specialty == "all"
