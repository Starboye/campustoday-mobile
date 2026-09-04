# CampusToday Mobile — Roadmap (Phases 1–6)

This document tracks work **after** the first slice (login + student homework).

## Phase 1 — Student app (remaining)

- [ ] Student dashboard (`/student/dashboard`)
- [ ] Announcements read + mark read
- [ ] Timetable (approved only)
- [ ] Fees read-only
- [ ] Report card + PDF download (Dompdf in API)

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

- [ ] FCM push, biometrics, offline attendance queue
- [ ] Deep links, tablet layouts, store listings

## Phase 6 — Hardening

- [ ] Load tests, permission matrix, dual-write regression suite

All phases use the **same Apache/MariaDB host** as SchoolCRM. SchoolCRM PHP files remain frozen.
