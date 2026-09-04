# CampusToday Mobile — Roadmap (Phases 0–6)

This document tracks work **after** the first slice (login + student homework).

## First slice (shipped)

- [x] Auth — login, refresh, logout, change-password
- [x] `GET /me`, `PUT /me/device`
- [x] Student homework list (API + Flutter)
- [x] Teacher/admin Flutter shells
- [x] OpenAPI contract (`openapi.yaml`)

## Phase 0 — API foundation (100%)

- [x] SQLite testing schema (`database/migrations/testing/`) + `TestingSeeder`
- [x] `PermissionMatrixTest` — admin routes 403/200 by permission key
- [x] `scripts/dual_stack_regression.php` — homework, attendance PUT, student dashboard
- [x] `openapi.yaml` synced with routes + Flutter aliases (`/marks`, `/attendance-locks`, `/fees/payments`)
- [x] `.env.example` documents JWT, DB, rate-limit vars; `phpunit.xml` uses sqlite memory

## Phase 1 — Student app (100%)

- [x] Student dashboard (`/student/dashboard`)
- [x] Announcements read + mark read
- [x] Timetable (approved only)
- [x] Fees read-only
- [x] Report card + PDF download (Dompdf in API, Share in Flutter)
- [x] Offline read-cache for homework/timetable/fees (`StudentReadCache`)

## Phase 2 — Teacher (100%)

- [x] Attendance GET/PUT — `class` query param, lock-day error, refetch after offline sync
- [x] Homework CRUD — edit route loads item by id (`TeacherHomeworkEditLoader`)
- [x] Marks PUT body matches `Teacher\MarksController` validation
- [x] Class timetable draft edit + submit

## Phase 3 — Admin core (100%)

- [x] Dashboard, students, teachers — delete wired on detail screens
- [x] Fees — structures CRUD + payment status update in `fees_screen.dart`
- [x] Marks — create/edit via POST/PUT `/admin/marks`
- [x] Notifications — templates list + send now UI
- [x] Approvals — approve/reject with note (`notes` field)

## Phase 4 — Admin complete (100%)

- [x] Delegation — `/admin/people/delegation` + assign roles flow
- [x] Planner tablet — master-detail grid at width ≥ 900; phone keeps tabs
- [x] Bulk — upload progress + API result card
- [x] Data quality — resolve/ignore on list + detail sheet
- [x] RBAC — assign roles from roles list and delegation hub

## Phase 5 — Native quality

- [x] FCM push stub (`FcmService` — needs Firebase config for production)
- [x] Biometrics stub (`BiometricUnlock` — needs platform permissions)
- [x] Offline attendance queue (`AttendanceQueue` + sqflite — sync on reconnect)
- [x] Offline banner (`OfflineBanner` + `connectivity_plus`)
- [x] Deep links stub (`DeepLinkHandler` — wire `app_links` for production)
- [ ] Tablet layouts (non-planner), store listings

## Phase 6 — Hardening

- [x] Feature smoke tests (`TeacherAttendanceTest`, `AdminDashboardTest`, `PermissionMatrixTest`)
- [x] Permission matrix + dual-write regression script
- [ ] Load tests

**Status (Phases 0–4):** 100% — API foundation, student, teacher, admin core, and admin complete.

**Status (Phases 5–6):** Partial — native stubs and test suite landed; store listings and load tests remain.

All phases use the **same Apache/MariaDB host** as SchoolCRM. SchoolCRM PHP files remain frozen.
