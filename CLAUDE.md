# TrustyDr Patient App

This app is the patient-facing TrustyDr application.

Focus:
- doctor discovery
- booking flow
- appointment viewing
- responsive patient experience
- mobile-first UX
- desktop responsive containment

Architecture:
- Flutter
- Riverpod
- Firestore snapshot-driven UI
- low-read architecture

Important:
- appointments must read snapshot fields only
- avoid runtime joins
- preserve booking architecture
- preserve provider-only Firestore access

Do NOT:
- modify backend rules from this app
- introduce expensive Firestore reads
- modify doctor/admin workflows unnecessarily

UI Rules:
- preserve RTL
- preserve EN/AR/KU localization
- preserve mobile-first responsiveness
- desktop improvements must remain lightweight

Important Files:
- doctor_time_slot.dart
- booking pages
- home.dart
- speciality.dart
- my_appointments_page.dart