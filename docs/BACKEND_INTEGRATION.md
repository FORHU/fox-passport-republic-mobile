# Flutter ↔ Fox Passport API Integration Guide

This guide documents how the Flutter mobile app connects to `fox-passport-republic-api` — the production Express + Prisma + PostgreSQL + Redis backend.

---

## 📡 Connection Overview

```
fox-passport-republic-mobile      fox-passport-republic-api
  lib/core/config/                 src/routes/
  app_config.dart  ─────────►     /api/v1/auth/*
  (BASE_URL env)                   /api/v1/profile
                                   /api/v1/venues
                                   /api/v1/event-templates
```

The Flutter app reads `BASE_URL` from the environment file (`.env.dev` / `.env.prod`) via `flutter_dotenv`. It calls the Express API directly; it does not use the Next.js web app's `/api/proxy` route. The default dev value points directly at the backend on port 6002:

```
BASE_URL=http://localhost:6002/api/v1
USE_MOCK=false
```

Mocks are opt-in (`USE_MOCK=true`) for local UI demos. Development uses the real API unless explicitly overridden.

---

## ⚙️ Step-by-Step Setup

### 1. Start the backend

```bash
cd fox-passport-republic-api

# Copy and fill in environment variables
cp .env.example .env

# Start PostgreSQL + Redis via Docker
docker compose up -d

# Install dependencies and run migrations
pnpm install
pnpm run db:setup

# Start the dev server (port 6002)
pnpm run dev
```

### 2. Configure Flutter environment

Edit `fox-passport-republic-mobile/.env.dev`:

```env
ENVIRONMENT=dev
APP_NAME=Fox Passport (Dev)
BASE_URL=http://localhost:6002/api/v1
ENABLE_LOGGING=true
USE_MOCK=false
```

> **Android emulator note**: Replace `localhost` with `10.0.2.2` when running on Android emulator, as `localhost` inside an emulator refers to the emulator's loopback, not your host machine:
> ```
> BASE_URL=http://10.0.2.2:6002/api/v1
> ```
> For a physical phone, use the computer's reachable LAN IP address. Keep `localhost` for Flutter web or a simulator on the same computer.

### 3. Run the Flutter app

```bash
cd fox-passport-republic-mobile
flutter run --target lib/main_dev.dart
```

---

## 🔐 Authentication Flow

The Flutter app implements the same **JWT token protocol** defined in the ecosystem auth contract:

| Step | Flutter (Client) | Node Backend |
| :--- | :--- | :--- |
| **Register** | `POST /api/v1/auth/register` | Creates the user and refresh-token record; sends an email verification OTP |
| **Login** | `POST /api/v1/auth/login` | Returns `{ accessToken, refreshToken, user }` and session cookies |
| **Store tokens** | `flutter_secure_storage` (keychain/keystore) | — |
| **Attach token** | Dio interceptor adds `Authorization: Bearer <accessToken>` | — |
| **Token refresh** | `POST /api/v1/auth/refresh-token` with `refreshToken` | Rotates and returns the token pair; the app must store both |
| **Logout** | `POST /api/v1/auth/logout` with `refreshToken` | Revokes the refresh-token session |
| **Get profile** | `GET /api/v1/users/me` | Returns user identity from Bearer token |

**Profile endpoint:** the mobile app loads the signed-in user from
`GET /api/v1/profile`, not the legacy `/api/v1/users/me` path shown above.

### Token Storage

Flutter uses `flutter_secure_storage` which maps to platform-native secure storage:
- **iOS**: Keychain
- **Android**: Android Keystore / EncryptedSharedPreferences
- **Desktop**: OS credential manager

This is **more secure** than the web templates' `sessionStorage`.

---

## 🔄 API Response Contract

Response shapes vary by API module; do not assume every endpoint uses one
envelope. For example, auth returns token fields at the top level, Passport
returns `{ success, data }`, and notifications returns
`{ success, notifications, unreadCount }`. Data sources parse the shape owned
by their endpoint.

```json
{
  "success": true,
  "data": { ... }
}
```

Many API errors use a message body, for example:

```json
{
  "success": false,
  "message": "Unauthorized"
}
```

---

## 🌐 CORS Configuration

In development, the API allows loopback origins on any port. For Flutter Web against a non-loopback host/origin, add that exact origin to the API's `CORS_ORIGINS`. Native iOS/Android requests are not subject to browser CORS:

```env
# fox-passport-republic-api/.env
CORS_ORIGINS=http://localhost:55061,https://app.example.com
```

Native HTTP requests do not use browser CORS. The Flutter client does not add a tenant header; current API routes do not require one.

---

## 📦 Key Flutter Packages Used

| Package | Role |
| :--- | :--- |
| `dio` | HTTP client with interceptors |
| `dio_smart_retry` | Auto-retry on network failure |
| `flutter_secure_storage` | Secure JWT token persistence |
| `flutter_dotenv` | Reads `.env.dev` / `.env.prod` at runtime |
| `fpdart` | `Either<Failure, T>` error modeling for API responses |
| `flutter_riverpod` | State management (auth state, user session) |
