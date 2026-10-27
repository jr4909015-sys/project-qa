# School Reservation System

A monorepo for reserving school equipment and laboratories, with a React web client, Django API, and Flutter mobile client.

## Requirements

- Node.js 20+
- Python 3.11+
- Flutter 3.47+
- PostgreSQL 16 (or Docker Compose)

## Feature coverage

### React web application

- JWT sign-in/out, registration, password recovery, role-aware navigation, and admin user activation/role management.
- Reservation availability calendars, staff-approved schedule-change requests, filtered reservation history, printable confirmation numbers, and progress details.
- Profile photo, student/employee ID, department, contact details, and authenticated password changes.
- Equipment/laboratory problem reports with optional photos; authorized staff receive notifications and can update report status.
- Admin dashboard totals for equipment, availability, laboratories, reservation states, overdue loans, and recent audit events.
- Equipment and laboratory create/edit/archive flows, equipment image uploads, operating hours, and laboratory closures.
- Reservation requests, availability checks, approval/rejection with remarks, cancellation, and completion.
- Equipment checkout/return tracking, reservation/utilization reports, CSV and Excel exports, in-app notifications, and audit history.

### Flutter mobile application

- Secure sign-in/out and profile/password updates.
- Searchable equipment and laboratory catalogues, resource details, availability, and reservation requests.
- Reservation history/details/cancellation, in-app notifications, and borrowed-item due/return status.
- Authorized staff/admins can record equipment checkouts and returns from the borrowed-equipment screen.
- Admins can create and edit accounts, assign roles, search/filter the user list, and activate/deactivate accounts in the mobile User management screen.
- Availability calendars, status timelines, filtered history, schedule-change requests, and printable reservation confirmations use the same Django API as the web client.
- Search equipment by condition/category and laboratories by building/capacity; submit issue reports with optional photos and update the extended user profile.

### In-app reminders

The backend command creates idempotent in-app reminders for approved reservations approaching within 24 hours, reservation pickup reminders within one hour, equipment due within 24 hours, and daily overdue-loan reminders. Run it periodically (for example, hourly) with the Django environment and database used by the API:

```powershell
.\backend\.venv\Scripts\python.exe .\backend\manage.py send_reservation_reminders
```

No task scheduler or push-notification provider is configured by default. Schedule the command in Windows Task Scheduler or your deployment's job runner to deliver reminders automatically. Reports export to CSV and Excel; PDF export is not currently included.

## Start the web client

```powershell
npm --prefix frontend-web install
npm run dev
```

## Start the API

```powershell
Copy-Item .env.example .env
cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8001
```

## Create an administrator account

Create an administrator once in the backend database. The same account can sign in to both the web and mobile apps; do not create a separate account for each client.

From the repository root in PowerShell:

```powershell
.\backend\.venv\Scripts\python.exe .\backend\manage.py migrate
.\backend\.venv\Scripts\python.exe .\backend\manage.py createsuperuser
```

Django will prompt for the username, email, and password. Both clients accept either the username or email at sign-in. The web client sends administrator and staff accounts to the admin dashboard after sign-in. The mobile client sends signed-in users to its dashboard.

## Start the mobile client

Web and desktop clients use `http://127.0.0.1:8001/api/` by default. Android emulators use `http://10.0.2.2:8001/api/`. Set `--dart-define=API_BASE_URL=...` for another host.

Android release builds must include the API's reachable base URL. For a physical phone on the same trusted Wi-Fi network as the development server, find the computer's LAN IPv4 address and use it in the build URL. Start Django listening on all interfaces (`python manage.py runserver 0.0.0.0:8001`) and allow that IP in `DJANGO_ALLOWED_HOSTS` (along with `localhost,127.0.0.1`). For example:

```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.20:8001/api
```

Replace `192.168.1.20` with the server computer's actual LAN IP. Both clients then connect to the same API/database. The Android app permits HTTP for local development; use an HTTPS API URL for deployment and do not send credentials over an untrusted network. If the server IP or port changes, rebuild the APK with the new URL.

From the repository root, install Flutter dependencies with:

```powershell
flutter pub get --directory=mobile-app
```

Then start the app from its project directory:

```powershell
Set-Location .\mobile-app
flutter run
```

Set environment values from the root `.env.example`. The standalone API command above uses port 8001; Docker Compose exposes the API on port 8000. Replace example secrets before deployment. School branding images are not included; add the school's approved logo and favicon under `frontend-web/public/`.

## Services

`docker compose up --build` starts PostgreSQL, the Django API, and the web client on port 8000. Flutter is run separately on a device or emulator.