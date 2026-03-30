# Pending Tasks — Requires External Infrastructure

These features are stubbed in the codebase and ready to implement once the supporting
infrastructure is provisioned. CloudFormation templates will live in a separate repo.

---

## Image Upload

**Status:** `throw APIError.notSupported` in `APIRemoteDataSource.uploadImage`

**What's needed:**
- S3 bucket for property and profile images
- CloudFront distribution in front of the bucket for CDN delivery
- `POST /api/v1/upload/presign` endpoint in the Go API that returns a presigned S3 URL
- iOS side: replace `notSupported` throw with a two-step upload:
  1. Request presigned URL from API
  2. PUT image data directly to S3
  3. Pass the resulting CloudFront URL as the image URL when creating/updating a property

**CloudFormation resources needed:**
- `AWS::S3::Bucket` (with CORS policy for direct upload)
- `AWS::CloudFront::Distribution`
- `AWS::IAM::Role` for API server to generate presigned URLs

---

## Apple Sign In

**Status:** `throw APIError.notSupported` in `APIAuthenticationService.signInWithApple`

**What's needed:**
- `POST /api/v1/auth/signin/apple` endpoint in the Go API that:
  1. Verifies the Apple identity token against Apple's public keys
  2. Creates or retrieves a user record
  3. Returns the same `authResponse` (access + refresh tokens)
- iOS side: remove the `notSupported` throw and call the new endpoint

**No AWS required** — Apple token verification uses Apple's public JWKS endpoint.
Can be implemented as soon as the API work is done.

---

## Google Sign In

**Status:** TODO comment in `LoginView.swift`, `throw APIError.notSupported` in `APIAuthenticationService.signInWithGoogle`

**What's needed:**
- Integrate the Google Sign-In SDK into the iOS project (via SPM)
- `POST /api/v1/auth/signin/google` endpoint in the Go API that:
  1. Verifies the Google ID token against Google's public keys
  2. Creates or retrieves a user record
  3. Returns the same `authResponse`
- iOS side: wire up the Google SDK button in `LoginView` and call the new endpoint

**No AWS required** — Google token verification uses Google's public JWKS endpoint.

---

## Push Notifications

**Status:** Not started

**What's needed:**
- APNs certificate or key configured in the Go API
- `POST /api/v1/devices` endpoint to register device tokens
- Notification triggers (e.g. new listing matching saved search, price drop, offer received)
- iOS side: request notification permission, send device token to API on login

**CloudFormation resources needed:**
- `AWS::SNS::Topic` per notification type (or use SNS platform application for APNs)
- `AWS::SNS::PlatformApplication` for APNs
