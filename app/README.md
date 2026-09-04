# CampusToday Flutter App

Single Flutter codebase for Student, Teacher, and Admin roles. Connects to **CampusToday-API** on the same server as SchoolCRM.

## Prerequisites

- Flutter 3.x / Dart 3
- CampusToday-API running (see `../CampusToday-API/README.md`)

## First-time setup

If `android/` and `ios/` folders are missing, generate platform projects:

```powershell
cd C:\xampp\htdocs\campustoday_app
flutter create --org com.campustoday --project-name campustoday_app .
flutter pub get
```

## API base URL

Default: `http://10.0.2.2:8080/v1` (Android emulator → host machine).

Override at build/run time:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/v1
```

For Apache alias on same XAMPP host:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10/api/v1
```

## Demo login (if DB seeded per `SchoolCRM/docs/DEMO_CREDENTIALS.md`)

| Role | Username | Password | access |
|------|----------|----------|--------|
| Student | `aditya.krishnan` | `Demo@2026` | 0 |
| Teacher | `priya.ramachandran` | `Demo@2026` | 1 |
| Admin | `admin` | `Demo@2026` | 2 |

## Structure

```
lib/
  app.dart
  main.dart
  core/
  features/auth/
  features/student/
  features/teacher/
  features/admin/
  shared/
```

Branding: `#4154F1` primary, `#012970` navy — matches `SchoolCRM/assets/css/brand.css`.
