# FootTech v2 — Backend (Coach / Adjoint / Joueur)

Express + TypeScript + PostgreSQL API aligned with `foottech_v2_schema.sql`
(bundled in this repo) — the simplified cahier des charges plus the fields
pulled from the club's real documents (fiche joueur, planning type, fiche
d'entrainement, bilan de saison).

Tested end-to-end in a real environment against PostgreSQL 16: coach
self-registration, team creation, adjoint invitation, player creation +
phone-OTP activation, full player fiche (guardian/address/school/season
profile/injury), training + technical sheet + situations + tactical drawing,
attendance, match + AI-scored lineup recommendations + live events +
per-player stats + evaluations, and the season bilan view (mirrors
`Bilan_Cadet_A.xlsx`). `tsc --noEmit` and `npm run build` both pass clean.

## Setup

```bash
npm install
cp .env.example .env   # fill in DB credentials + JWT secrets
psql -U postgres -c "CREATE DATABASE foottech;"
psql -U postgres -d foottech -f foottech_v2_schema.sql
npm run dev       # ts-node-dev, hot reload
npm run build && npm start
npm run typecheck
```

REST: `http://localhost:4000/api/v1/...` · Swagger: `/docs` · Health: `/health`
Socket.io: same port, auth via `{ auth: { token: <accessToken> } }`.

## Auth model (important — two different login flows)

- **Coach**: self-registers with email + password (`POST /auth/register-coach`),
  active immediately.
- **Adjoint**: created by their Coach (`POST /teams/:id/staff`) as an
  INACTIVE account with no password; they activate via
  `POST /auth/set-adjoint-password` (userId + a password they choose —
  wire a real invite-link/SMS step around this in production).
- **Joueur**: created by Coach/Adjoint (`POST /players`) as an INACTIVE
  account with a phone number, no password ever. They log in via
  `POST /auth/player/request-otp` (sends/logs a 6-digit code) then
  `POST /auth/player/verify-otp` — this also activates the account on
  first successful verification.
- `GET /auth/me`, `POST /auth/refresh`, `POST /auth/logout` are shared.
- The JWT's `teamId` claim is a convenience only — **dashboard and any
  team-scoped read that needs it resolves it fresh from the DB** rather
  than trusting the token, because a Coach creating their first team
  *after* registering would otherwise carry a stale null teamId until
  their next token refresh. This was caught by the end-to-end test run,
  not just reasoned about — worth keeping in mind if you add new
  teamId-dependent endpoints: resolve it fresh, don't trust the claim.

## Modules

Same layered pattern in every `src/modules/<name>/`:
`<name>.routes.ts` → `.controller.ts` → `.service.ts` → `.repository.ts`,
plus `.dto.ts` / `.validation.ts` (Zod) / `.interface.ts` / `.types.ts`.
`shared/database/BaseRepository.ts` (with an added `upsert()` used heavily
here for the one-row-per-relation/season/conflict-key patterns) provides
generic CRUD; every module adds its own queries on top.

- **auth** — dual login flow described above, rotating refresh tokens.
- **users** — profile + avatar upload (`POST /users/:id/avatar`, multer,
  served from `/uploads`).
- **teams** — Coach-owned, manages Adjoint roster.
- **players** — the rich fiche: base profile + nested
  guardians/address/school-info/season-profile (one row per season,
  reproduces the club's 15/16→24/25 tracking)/injuries.
- **seasons** — simple CRUD, one `is_current` at a time.
- **weekly-plannings** — the club's weekly planning grid (criteres +
  jour×moment slots linkable to a real training).
- **trainings** — training + technical sheet (objectifs/effectif) +
  ordered situations (duree travail/recup, criteres de reussite) + a
  JSONB tactical drawing per situation (TacticalPad-style canvas data,
  free-form on purpose — no rigid schema for player/arrow positions).
- **exercise-proposals** — Adjoint proposes, Coach validates/rejects.
- **attendance** — present/absent/late/injured per training.
- **matches** — lineup selection, a transparent 3-factor AI recommendation
  score (presence/performance/fatigue → weighted final score, see
  `matches.repository.ts` `computeAndStoreRecommendations` for the exact
  SQL and weights), live event timeline (goals auto-bump the scoreboard),
  per-player match stats, evaluations, PDF report pointer.
- **notifications** — per-user + team-broadcast, push token registration
  (FCM/APNs wiring left as a TODO — see `shared/utils/otp.ts` for the same
  "logs instead of sending" pattern used for OTP codes without a
  configured provider).
- **dashboard** — role-adaptive summary + the `player_season_bilan` SQL
  view exposed at `/dashboard/season-bilan`.

## Known gaps / next steps

- SMS/WhatsApp OTP delivery and push notifications are stubbed (logged via
  winston, not actually sent) until a provider is configured — see
  `SMS_PROVIDER_API_KEY` in `.env.example`.
- No automated test suite yet — validated via a real end-to-end run against
  a live PostgreSQL instance instead (see the module list above for what
  was exercised).
- Match report PDF generation itself isn't implemented — `POST /matches/:id/report`
  just stores a URL you'd generate elsewhere.
# FoottechBackend
