# CampusToday Mobile API

JSON API for the CampusToday Flutter app. Part of the **[campustoday-mobile](https://github.com/Starboye/campustoday-mobile)** monorepo (`api/` folder).

Runs on the **same Apache/MariaDB host** as SchoolCRM; does not modify the PHP web app.

## Requirements

- PHP 8.2+ (XAMPP)
- MariaDB `asimos` (same DB as web)
- Composer

## Setup

```powershell
cd C:\xampp\htdocs\campustoday-mobile\api
C:\xampp\php\php.exe C:\xampp\htdocs\composer.phar install
copy .env.example .env
C:\xampp\php\php.exe artisan key:generate
C:\xampp\php\php.exe artisan migrate --path=database/migrations/2026_09_05_000001_create_api_tables.php
```

Configure `.env`:

```
DB_DATABASE=asimos
DB_USERNAME=root
DB_PASSWORD=
```

## Apache (same server as SchoolCRM)

See [`docs/APACHE_SETUP.md`](docs/APACHE_SETUP.md). Alias target:

`C:/xampp/htdocs/campustoday-mobile/api/public`

## Quick local dev

```powershell
C:\xampp\php\php.exe artisan serve --host=0.0.0.0 --port=8080
```

Base URL: `http://127.0.0.1:8080/v1`

## OpenAPI

See `openapi.yaml` for the full contract.

## Notes

- Password verify/rehash matches SchoolCRM web login rules.
- Writes to existing `login_audit` on login.
- Additive tables only: `api_refresh_tokens`, `api_devices`.
- SchoolCRM PHP tree is **not** modified by this project.
