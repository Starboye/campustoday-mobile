# CampusToday Mobile API

JSON API for the CampusToday Flutter app. Runs on the **same Apache/MariaDB host** as SchoolCRM; does not modify the PHP web app.

## Requirements

- PHP 8.2+ (XAMPP)
- MariaDB `asimos` (same DB as web)
- Composer

## Setup

```powershell
cd C:\xampp\htdocs\CampusToday-API
C:\xampp\php\php.exe C:\xampp\htdocs\composer.phar install
copy .env.example .env   # if needed
C:\xampp\php\php.exe artisan key:generate
C:\xampp\php\php.exe artisan migrate --path=database/migrations/2026_09_05_000001_create_api_tables.php
```

Configure `.env`:

```
DB_DATABASE=asimos
DB_USERNAME=root
DB_PASSWORD=
JWT_SECRET=<same as APP_KEY or separate secret>
```

## Apache (same server as SchoolCRM)

Add to `C:\xampp\apache\conf\extra\httpd-vhosts.conf` (or `httpd.conf`):

```apache
Alias /api "C:/xampp/htdocs/CampusToday-API/public"
<Directory "C:/xampp/htdocs/CampusToday-API/public">
    AllowOverride All
    Require all granted
</Directory>
```

Restart Apache. API base URL: `http://localhost/api/v1`

Alternative for quick local dev:

```powershell
C:\xampp\php\php.exe artisan serve --host=0.0.0.0 --port=8080
```

Base URL: `http://<your-lan-ip>:8080/v1`

## Endpoints (first slice)

| Method | Path | Auth |
|--------|------|------|
| GET | `/v1/health` | No |
| POST | `/v1/auth/login` | No |
| POST | `/v1/auth/refresh` | No |
| POST | `/v1/auth/logout` | No |
| GET | `/v1/me` | Bearer |
| POST | `/v1/auth/change-password` | Bearer |
| GET | `/v1/student/homework?date=YYYY-MM-DD` | Bearer (student) |

### Login body

```json
{
  "username": "student_username",
  "password": "password",
  "access": 0
}
```

`access`: `0` = student, `1` = teacher, `2` = admin (must match `user_login.access`).

## OpenAPI

See `openapi.yaml` for the contract.

## Notes

- Password verify/rehash matches `backoffice/login.php` / `config/app.php`.
- Writes to existing `login_audit` on login.
- Additive tables only: `api_refresh_tokens`, `api_devices`.
- SchoolCRM PHP tree is **not** modified by this project.
