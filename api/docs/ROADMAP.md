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

- [ ] Attendance GET/PUT with day-lock checks
- [ ] Homework CRUD
- [ ] Marks (`marks` table)
- [ ] Announcements POST
- [ ] Student dossier (scoped)
- [ ] Class timetable draft/submit

## Phase 3 — Admin core

- [ ] Dashboard, students, teachers
- [ ] Attendance + locks, homework, marks_new, fees
- [ ] Approvals, notifications

## Phase 4 — Admin complete

- [ ] Planner (tablet-first), exams, analytics
- [ ] Security, RBAC, delegation, bulk, data quality

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
