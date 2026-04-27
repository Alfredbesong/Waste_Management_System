# Smart Waste Management MVP

This repository is a single monorepo for the smart waste management MVP.

- The Flutter citizen app lives at the repository root in `lib/`
- The Django backend and admin dashboard live in `backend/`
- Shared notes and structure guidance live in `docs/`

## What is implemented now

- Flutter app shell with login, register, reporting, reports list, detail, and confirmation screens
- Flutter profile page with editable account info, profile photo upload, logout, and delete account actions
- Django REST API with JWT auth, waste reports, and confirmation endpoints
- Firebase push notifications for report status updates
- Photo upload support for waste reports
- Photo upload support for user profile pictures
- Basic security rules so citizens cannot edit admin-only report status updates
- Backend tests for auth and report permissions
- A small Flutter API client so the screens can talk to the backend

## Recent additions

- Users can now update `username`, `email`, `first_name`, `last_name`, and `phone_number` from the profile page
- Users can tap the profile avatar to choose a profile picture from the gallery
- Users can remove an existing profile picture
- Django now stores profile images in `backend/media/profiles/`
- `GET /api/auth/me/` now returns `profile_photo`
- `PATCH /api/auth/me/` now updates profile data and accepts multipart image uploads

## Safe GitHub upload guide

Yes, you can upload this project to GitHub. The safe approach is:

- Upload source code, configs that are safe to share, documentation, and dependency manifests
- Do not upload local databases, generated media, private keys, local virtual environments, or production secrets

### Upload these

- `lib/`, `test/`, `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`
- `backend/apps/`, `backend/config/`, `backend/manage.py`, `backend/requirements.txt`
- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`
- `README.md`, `docs/`, `.gitignore`
- Django migrations, including the new profile photo migration

Reason:
- These files are the real project source and setup instructions contributors need to build, run, review, and extend the app.

### Do not upload these

- `backend/db.sqlite3`
- `backend/media/`
- `backend/.venv/`
- `.env`, `backend/.env`, and any secret env file
- Firebase service account JSON files
- signing keys such as `.jks`, `.keystore`, and `android/key.properties`
- `android/app/google-services.json` if this is your personal or production Firebase project
- build output folders such as `build/`, `.dart_tool/`, and cache folders

Reason:
- These contain private data, generated files, local machine state, binary assets that should be recreated, or credentials that could be abused if exposed.

## Security notes

- `DJANGO_SECRET_KEY` must not be committed in a real `.env` file. Keep it local and set it per environment.
- JWT tokens should never be hardcoded or committed.
- `backend/db.sqlite3` may contain real user accounts and app data, so it should stay out of GitHub.
- `backend/media/` can contain user-uploaded waste photos and profile pictures, so it should stay out of GitHub.
- `google-services.json` is not a backend secret, but it does identify your Firebase project. For a public repo, it is better to let contributors add their own Firebase config or use a separate non-production Firebase project.

## First-time GitHub upload

```powershell
git init
git add .
git commit -m "Initial smart waste management MVP"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git push -u origin main
```

If this repository is already initialized locally, use:

```powershell
git add .
git commit -m "Add profile editing and profile photo upload"
git push
```

## How users can pull and run the project

```powershell
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME
flutter pub get
```

Backend setup:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Flutter app setup in a new terminal:

```powershell
cd YOUR_REPO_NAME
flutter pub get
flutter run
```

If Firebase notifications are required, each user should add their own Firebase config files before running mobile builds.

## Run the backend first

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

## Run the Flutter app

```powershell
flutter pub get
flutter run
```

## MVP Flow

1. Citizen registers or logs in.
2. Citizen opens the profile page to edit account info, upload or remove a profile photo, logout, or delete the account.
3. Citizen creates a waste report with description, GPS location, and an optional photo.
4. Admin reviews the report and updates its status.
5. Citizen receives a notification when the report status changes.
6. Citizen confirms whether the waste is actually cleared.

## Status Flow

- Reported
- In Progress
- Resolved

## Backend API

- `POST /api/auth/register/`
- `POST /api/auth/token/`
- `POST /api/auth/token/refresh/`
- `GET /api/auth/me/`
- `PATCH /api/auth/me/`
- `DELETE /api/auth/me/delete/`
- `POST /api/auth/device-token/`
- `POST /api/reports/`
- `GET /api/reports/`
- `GET /api/reports/{id}/`
- `PATCH /api/reports/{id}/`
- `POST /api/confirm/`

## How Flutter Talks To Django

1. Flutter sends requests through the shared `ApiClient`.
2. Login returns JWT access and refresh tokens.
3. Flutter stores those tokens locally in `SessionStore`.
4. Every protected request sends the access token in the `Authorization: Bearer ...` header.
5. Django verifies the token and returns JSON data.
6. For image uploads, Flutter sends a multipart request and Django stores the file in `media/reports/`.
7. Profile photo uploads also use multipart requests and are stored in `media/profiles/`.
8. For notifications, Flutter sends the Firebase device token to Django, and Django sends push updates back to the user's device.

## Session Timing

- Flutter app access token lifetime: `60 minutes`
- Flutter app refresh token lifetime: `7 days`
- Django admin dashboard uses normal browser session login
- The session starts when a user logs in, not when they register

## Operating The System

- Start the Django backend first so the API is available.
- Create a superuser if you want to use the Django admin dashboard.
- Run the Flutter app on mobile, emulator, or web.
- Register or log in from the app before creating reports.
- Use the report form to auto-detect location and attach a photo if needed.
- Use the profile page to edit your details, manage your profile photo, log out, or delete your account.

## Notes

- The app uses token-based auth through JWT.
- The Flutter report form now supports optional photo upload through the image picker.
- Uploaded report photos are saved by Django under `media/reports/`.
- Uploaded profile photos are saved by Django under `media/profiles/`.
- The app can receive Firebase notifications when a report changes status.
- Comments in the code are intentionally short and simple so the logic stays easy to follow.
