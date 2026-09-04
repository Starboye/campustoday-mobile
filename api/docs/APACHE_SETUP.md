# CampusToday Mobile — Apache setup (same server as SchoolCRM)

Add to `C:\xampp\apache\conf\extra\httpd-vhosts.conf`:

```apache
# CampusToday Mobile API (does not modify SchoolCRM)
Alias /api "C:/xampp/htdocs/CampusToday-API/public"
<Directory "C:/xampp/htdocs/CampusToday-API/public">
    AllowOverride All
    Require all granted
</Directory>
```

Restart Apache from XAMPP Control Panel.

## URLs

| Service | URL |
|---------|-----|
| SchoolCRM web | `http://localhost/SchoolCRM/` |
| Mobile API | `http://localhost/api/v1/health` |
| Flutter (device) | `--dart-define=API_BASE_URL=http://<PC-LAN-IP>/api/v1` |

## Verify dual-stack (homework)

1. Log in on web as student `aditya.krishnan` / `Demo@2026`
2. Open Homework for today's date — note assignments for class 8-A
3. Call API:
   ```powershell
   $body = '{"username":"aditya.krishnan","password":"Demo@2026","access":0}'
   $login = Invoke-RestMethod -Uri "http://localhost/api/v1/auth/login" -Method POST -Body $body -ContentType "application/json"
   $h = @{ Authorization = "Bearer $($login.access_token)" }
   Invoke-RestMethod -Uri "http://localhost/api/v1/student/homework?date=2026-09-04" -Headers $h
   ```
4. Same `homeworks` rows appear in both (same `id`, `title`, `subject_name`).

## Windows Task Scheduler (later — notification cron)

```
Program: C:\xampp\php\php.exe
Arguments: C:\xampp\htdocs\CampusToday-API\artisan schedule:run
Start in: C:\xampp\htdocs\CampusToday-API
Trigger: Every 1 minute
```
