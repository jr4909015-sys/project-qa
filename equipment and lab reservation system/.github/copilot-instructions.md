# Workspace Instructions

## Project

This repository is a school equipment and laboratory reservation monorepo:

- `frontend-web/`: React and Vite client
- `backend/`: Django REST API and SQLite/PostgreSQL configuration
- `mobile-app/`: Flutter client

## Development

- Keep changes within the owning client or backend app and preserve the API contract.
- The API exposes public read-only equipment and laboratory catalogues, JWT authentication at `/api/auth/token/`, and authenticated reservation endpoints at `/api/reservations/`.
- Do not commit `.env`, virtual environments, database files, media uploads, or build output.
- Add only approved school branding and licensed media to asset directories.

## Setup Checklist

- [x] Requirements and project structure defined
- [x] React, Django, and Flutter scaffolds created
- [x] Frontend dependencies installed
- [x] Backend dependencies installed in `backend/.venv`
- [x] Flutter dependencies resolved
- [x] Frontend build, Django checks/tests, and Flutter analysis verified
- [x] README and environment example documented
- [ ] Launch the application after the user confirms a run mode

## Local Commands

- Web: `cd frontend-web`, `npm install`, `npm run dev`
- API: `cd backend`, activate `.venv`, `pip install -r requirements.txt`, then `python manage.py migrate` and `python manage.py runserver`
- Mobile: `cd mobile-app`, `flutter pub get`, then `flutter run`
- Compose: copy `.env.example` to `.env`, then run `docker compose up --build`
