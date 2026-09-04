# CampusToday Mobile — Roadmap (Phases 1–6)

This document tracks work **after** the first slice (login + student homework).

## First slice (shipped)

- [x] Auth — login, refresh, logout, change-password
- [x] `GET /me`, `PUT /me/device`
- [x] Student homework list (API + Flutter)
- [x] Teacher/admin Flutter shells (stubs)
- [x] OpenAPI contract (`openapi.yaml`)

## Phase 1 — Student app (remaining)

- [x] Student dashboard (`/student/dashboard`)
- [x] Announcements read + mark read
- [x] Timetable (approved only)
- [x] Fees read-only
- [x] Report card + PDF download (Dompdf in API)

## Phase 2 — Teacher

- [x] Attendance GET/PUT with day-lock checks (`Teacher\AttendanceController`, Flutter attendance tab)
- [x] Homework CRUD (`Teacher\HomeworkController`, work hub screens)
- [x] Marks (`marks` table — `Teacher\MarksController`)
- [x] Announcements POST (`Teacher\AnnouncementsController`)
- [x] Student dossier (scoped — `Teacher\StudentsController`, students tab)
- [x] Class timetable draft/submit (`Teacher\ClassTimetableController`)

## Phase 3 — Admin core

- [x] Dashboard, students, teachers (controllers + Flutter screens)
- [x] Attendance + locks, homework, marks_new, fees (controllers + Flutter screens)
- [x] Approvals, notifications (controllers + Flutter screens)

## Phase 4 — Admin complete

- [x] Planner (tablet-first), exams, analytics (controllers + Flutter screens)
- [x] Security, RBAC, delegation, bulk, data quality (controllers; Flutter admin shell owned separately)

## Phase 5 — Native quality

- [x] FCM push stub (`FcmService` — needs Firebase config for production)
- [x] Biometrics stub (`BiometricUnlock` — needs platform permissions)
- [ ] Offline attendance queue
- [x] Offline banner stub (`OfflineBanner` — wire `connectivity_plus` for production)
- [x] Deep links stub (`DeepLinkHandler` — wire `app_links` for production)
- [ ] Tablet layouts, store listings

## Phase 6 — Hardening

- [ ] Load tests, permission matrix, dual-write regression suite

All phases use the **same Apache/MariaDB host** as SchoolCRM. SchoolCRM PHP files remain frozen.

**Note:** Admin HTTP routes in `api_admin.php` are still being wired by AdminAPI-Agent; controllers and Flutter screens exist ahead of route registration.
