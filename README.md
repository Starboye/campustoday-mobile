# CampusToday Mobile

**Single source of truth:** [github.com/Starboye/campustoday-mobile](https://github.com/Starboye/campustoday-mobile)

Clone or pull this repo only. Do **not** use separate `CampusToday-API` or `campustoday_app` folders under `htdocs`.

Monorepo for the CampusToday mobile stack (same MariaDB `asimos` as [SchoolCRM](https://github.com/Starboye/SchoolCRM); web PHP unchanged).

| Folder | Description |
|--------|-------------|
| [`api/`](api/) | Laravel JSON API — JWT auth, `/v1/*` endpoints |
| [`app/`](app/) | Flutter app — student / teacher / admin |

## Local path (XAMPP)

```
C:\xampp\htdocs\campustoday-mobile\
  api\     ← Laravel (Apache alias /api → api/public)
  app\     ← Flutter
```

## Quick start

### API
```powershell
cd C:\xampp\htdocs\campustoday-mobile\api
copy .env.example .env
C:\xampp\php\php.exe C:\xampp\htdocs\composer.phar install
C:\xampp\php\php.exe artisan key:generate
C:\xampp\php\php.exe artisan migrate --path=database/migrations/2026_09_05_000001_create_api_tables.php
C:\xampp\php\php.exe artisan serve --host=0.0.0.0 --port=8080
```

### Flutter
```powershell
cd C:\xampp\htdocs\campustoday-mobile\app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/v1
```

See `api/README.md`, `api/docs/APACHE_SETUP.md`, and `app/README.md`.

Roadmap: `api/docs/ROADMAP.md`
