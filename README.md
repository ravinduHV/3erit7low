# MeritFlow — Scout Progress Tracker

> A modular Scout progress tracking app for Scouts of Sri Lanka. Scouts can track their badges and awards across all six sections, with a fully configurable admin panel and rule-based recommendations.

---

## Project Structure (Monorepo)

```
ScoutProgressApp/
├── frontend/        # Flutter app (iOS, Android, Web)
├── backend/         # FastAPI Python API
└── auth-service/    # Node.js better-auth service (Neon Auth proxy)
```

---

## Scout Sections Supported

| Section | Age Range |
|---|---|
| Singithi Scout | 5–8 years |
| Cub Scout | 8–11 years |
| Junior Scout | 11–14 years |
| Senior Scout | 14–17 years |
| Rover Scout | 17–25 years |
| Scout Leader | Adult |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) — BLoC + Clean Architecture |
| Backend API | FastAPI (Python) + SQLAlchemy + Alembic |
| Auth Service | Node.js + better-auth (Neon Auth Proxy) |
| Database | Neon PostgreSQL (serverless) |
| Routing | go_router |
| State Management | flutter_bloc |

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.x
- Python 3.11+
- Node.js 20+
- A [Neon](https://neon.tech) PostgreSQL database

---

### 1. Auth Service

```bash
cd auth-service
cp .env.example .env
# Fill in your Neon DB URL and a strong BETTER_AUTH_SECRET
npm install
npm run dev
```

### 2. Backend API

```bash
cd backend
cp .env.example .env
# Fill in your Neon DB URL and BETTER_AUTH_SECRET (same as auth-service)
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python seed.py   # Seed initial syllabus data
python main.py   # Start server on port 8000
```

### 3. Flutter Frontend

```bash
cd frontend
flutter pub get
flutter run
```

---

## Environment Variables

Each service uses a `.env` file. Copy `.env.example` to `.env` in each service directory and fill in your values.

| Variable | Service | Description |
|---|---|---|
| `DATABASE_URL` | backend, auth-service | Neon PostgreSQL connection string |
| `BETTER_AUTH_SECRET` | backend, auth-service | Shared JWT secret (must match!) |
| `BETTER_AUTH_URL` | auth-service | Public URL of auth service |
| `PORT` | backend, auth-service | Port number |

> ⚠️ **Never commit `.env` files.** They are excluded by `.gitignore`.

---

## Admin Panel

Scout Leaders with `is_admin=true` can access the Admin panel to:
- Create/edit/delete Scout sections
- Configure awards and requirements (CRUD)
- Set age, service time, and pool requirements
- Manage eligibility rules

---

## License

Private — Sri Lanka Scouts. All rights reserved.
