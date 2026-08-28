# 08 — Auth, Session & Onboarding

## Supported Backend Features

- **Two-Step Email OTP Registration**:
  - `POST /api/v1/auth/register/request-otp`: Sends 6-digit verification code to email (5-minute TTL).
  - `POST /api/v1/auth/register/verify-otp`: Validates OTP, auto-generates unique username, creates user & profile in PostgreSQL, returns JWT session tokens.
- **Username Availability Check**:
  - `GET /api/v1/users/check-username?username=...`: Real-time availability check for profile setup and settings.
- **Login & Token Management**:
  - `POST /api/v1/auth/login`: Authenticate with username/email and password.
  - `POST /api/v1/auth/refresh`: Refresh expired access token using refresh token.
  - `POST /api/v1/auth/logout`: Revoke session tokens.
- **Password Reset Flow**:
  - `POST /api/v1/auth/forgot-password`: Dispatch 6-digit reset OTP to email (5-minute TTL).
  - `POST /api/v1/auth/verify-otp`: Verify reset OTP and issue access token for password change.
  - `POST /api/v1/auth/reset-password`: Set new password with verified token.
- **Interest Onboarding**:
  - `GET /api/v1/interests`: Retrieve catalog of interest categories.
  - `PUT /api/v1/profiles/me/interests`: Save selected user interests.

---

## Session & Navigation Flow

```text
Launch
  ↓
Read Secure Session Storage
  ↓
Access token valid?
  ├─ Yes → Has Onboarded?
  │          ├─ Yes → Main Shell Feed (/feed)
  │          └─ No  → Interest Onboarding (/onboarding)
  └─ No/Unknown → Attempt Refresh Token
                    ├─ Success → Load Profile → Main Shell Feed (/feed)
                    └─ Failure → Login Screen (/login)
```

---

## Registration Flow

```text
Register Screen (/register)
(Inputs: Email & Password only - min 8 chars)
  ↓
Submit → POST /api/v1/auth/register/request-otp (5-minute OTP)
  ↓
Verify OTP Screen (/verify-otp?flow=signup)
(User enters 6-digit code sent to Gmail)
  ↓
Submit → POST /api/v1/auth/register/verify-otp
(Validates OTP, auto-generates unique username, creates PostgreSQL records, issues JWTs)
  ↓
Profile Setup Screen (/profile-setup)
(Customize Display Name & Avatar presets, real-time username validation, or "Skip for Now")
  ↓
Interest Onboarding (/onboarding)
(Select interests from catalog)
  ↓
Main Shell Feed (/feed)
```

---

## Password Reset Flow

```text
Forgot Password Screen (/forgot-password)
(Input: Email address)
  ↓
Submit → POST /api/v1/auth/forgot-password (5-minute OTP)
  ↓
Verify OTP Screen (/verify-otp)
(User enters 6-digit code)
  ↓
Decision View (Modal / Prompt)
  ├─ "Update Password Now" → Reset Password Screen (/reset-password) → Success → Main Shell Feed
  └─ "Skip to Feed" → Main Shell Feed (/feed)
```

---

## Logout

1. Call backend logout: `POST /api/v1/auth/logout` with `refresh_token`.
2. Clear secure local storage tokens (`accessToken`, `refreshToken`).
3. Clear user session preferences.
4. Reset router navigation to `/login`.
