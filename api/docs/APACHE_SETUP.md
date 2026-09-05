# CampusToday Mobile — Apache setup (same server as SchoolCRM)

Add to `C:\xampp\apache\conf\extra\httpd-vhosts.conf`:

```apache
# CampusToday Mobile API (monorepo: campustoday-mobile/api)
Alias /api "C:/xampp/htdocs/campustoday-mobile/api/public"
<Directory "C:/xampp/htdocs/campustoday-mobile/api/public">
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
2. Open Homework for today's date
3. Call API:
   ```powershell
   $body = '{"username":"aditya.krishnan","password":"Demo@2026","access":0}'
   $login = Invoke-RestMethod -Uri "http://localhost/api/v1/auth/login" -Method POST -Body $body -ContentType "application/json"
   $h = @{ Authorization = "Bearer $($login.access_token)" }
   Invoke-RestMethod -Uri "http://localhost/api/v1/student/homework?date=2026-09-04" -Headers $h
   ```

## Windows Task Scheduler (notification cron)

```
Program: C:\xampp\php\php.exe
Arguments: C:\xampp\htdocs\campustoday-mobile\api\artisan schedule:run
Start in: C:\xampp\htdocs\campustoday-mobile\api
Trigger: Every 1 minute
```
