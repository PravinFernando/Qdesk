# qdesk — HR Management Platform

A modern, mobile-first HR management application built with Flutter and Firebase. qdesk simplifies everyday workplace operations — from attendance tracking to reimbursements — in one clean, role-based mobile app.

---

## Features

- **Role-Based Login** — Separate dashboards for Admin, Manager, and Employee
- **Attendance Management** — Check-in/Check-out with monthly calendar view
- **Daily Sheet** — Employees log daily work; managers review team entries
- **Reimbursements** — Submit expense claims with approval workflow
- **Manager Dashboard** — Team activity view, missing entries tracker
- **Admin Panel** — Full control over users, attendance, daily sheets, reimbursements, and CSV export
- **Password Management** — Employee self-change and admin reset via email
- **User Access Control** — Enable/disable employees instantly
- **Splash Screen** — Smooth fade and scale animation on launch
- **Filters** — Filter reimbursements by month and employee name

---

## Tech Stack

| Technology | Usage |
|---|---|
| Flutter | Cross-platform mobile app (Android & iOS) |
| Firebase Auth | Secure login and authentication |
| Cloud Firestore | Real-time database |
| Firebase Storage | Receipt image storage |

---

## Firestore Collections

| Collection | Description |
|---|---|
| `users` | Stores user profile, role, department, reportsTo |
| `attendance` | Daily check-in/check-out records |
| `daily_entries` | Employee daily work logs |
| `reimbursements` | Expense claims with status tracking |

---

## User Roles

| Role | Access |
|---|---|
| **Admin** | Full access — manage users, approve reimbursements, export data |
| **Manager** | View team daily sheets, track missing entries |
| **Employee** | Attendance, daily sheet, reimbursement submission |

---

## Project Structure

```
lib/
├── screens/
│   ├── employee/        # Employee home, attendance, daily sheet, reimbursements
│   ├── manager/         # Manager dashboard
│   ├── admin/           # Admin panel
│   ├── auth/            # Login screen
│   └── common/          # Shared screens (change password, splash)
├── services/            # Auth, Firestore, Attendance, Daily entry services
├── widgets/             # Reusable widgets (attendance calendar)
└── models/              # Data models
```

---

## Theme

- Background: `#0B1020`
- Accent: `#D4AF37` (Gold)
- Dark, professional UI throughout

---

## Team

Built with ❤️ by **Gokul**, **Jindo**, and **Pravin**

---

## Future Scope

- Payroll generation based on attendance
- Receipt upload via Firebase Storage
- Push notifications for approvals
- Web dashboard for admin
- iOS App Store release