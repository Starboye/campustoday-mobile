# CampusToday Flutter App

Part of the **[campustoday-mobile](https://github.com/Starboye/campustoday-mobile)** monorepo (`app/` folder).

Single Flutter codebase for Student, Teacher, and Admin roles.

## Prerequisites

- Flutter 3.x / Dart 3
- API running (see [`../api/README.md`](../api/README.md))

## Setup

```powershell
cd C:\xampp\htdocs\campustoday-mobile\app
flutter pub get
```

## Run

```powershell
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/v1
```

For Apache on same XAMPP host:

```powershell
flutter run --dart-define=API_BASE_URL=http://<PC-LAN-IP>/api/v1
```

For Android emulator → host PC: use `10.0.2.2` instead of `127.0.0.1`.

## Demo login

| Role | Username | Password | access |
|------|----------|----------|--------|
| Student | `aditya.krishnan` | `Demo@2026` | 0 |
| Teacher | `priya.ramachandran` | `Demo@2026` | 1 |
| Admin | `admin` | `Demo@2026` | 2 |

Branding: `#4154F1` primary, `#012970` navy — matches SchoolCRM web.
