# CampusToday Mobile

Monorepo for the CampusToday mobile stack (same MariaDB `asimos` as [SchoolCRM](https://github.com/Starboye/SchoolCRM), web PHP unchanged).

| Folder | Description |
|--------|-------------|
| [`api/`](api/) | Laravel JSON API (`CampusToday-API`) — JWT auth, `/v1/*` endpoints |
| [`app/`](app/) | Flutter app — student / teacher / admin shells |

## Quick start

### API
```powershell
cd api
copy .env.example .env
composer install
php artisan key:generate
php artisan migrate --path=database/migrations/2026_09_05_000001_create_api_tables.php
php artisan serve --host=0.0.0.0 --port=8080
```

### Flutter
```powershell
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/v1
```

See `api/README.md`, `api/docs/APACHE_SETUP.md`, and `app/README.md` for details.

## Status (first slice)

- Login + refresh + `/me`
- Student homework list
- Teacher/admin shells (stubs)

Roadmap: `api/docs/ROADMAP.md`
