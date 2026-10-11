# AGENTS.md — exam_demo monorepo

One root repo, two deployables. Root owns git + CI + docs; never `git init` in subfolders, never recreate `exam_demo_web/.github`.

- `exam_demo_app/` — Flutter, app ujian **siswa**. Entry `lib/main.dart`, lints `flutter_lints` via `analysis_options.yaml`.
- `exam_demo_web/` — Laravel 13 + Livewire + Fortify. **API** untuk Flutter + dashboard **guru** (rekap) + **admin** (monitoring). Guru/admin murni Livewire/Blade, tidak lewat API.

## Commands (run inside the subfolder, not root)

```bash
cd exam_demo_web && composer setup    # install + key + migrate + npm build; needs PHP ^8.3, Node 22
cd exam_demo_web && composer test     # verify order: pint --test -> phpstan -> artisan test (Pest)
cd exam_demo_web && composer ci:check # what CI runs (= test above)
cd exam_demo_web && php artisan test --filter=FooTest  # single test
cd exam_demo_web && composer lint      # pint fix (lint:check = check only); types:check = phpstan (level 7)

cd exam_demo_app && flutter pub get && flutter analyze && flutter test
```

## Gotchas

- `composer setup` runs `npm run build`; `composer dev` runs server+queue+vite together.
- PHP tests need no external DB: `phpunit.xml` forces sqlite `:memory:`, Feature tests use `RefreshDatabase`. Default local DB is sqlite file (`DB_CONNECTION=sqlite` in `.env.example`).
- `vendor/`, `node_modules/`, `exam_demo_web/.env` exist locally but are git-ignored — never commit them.
- `bootstrap/app.php` already treats `api/*` as JSON.

## API contract (breaking-change hotspot)

- Source of truth: `docs/api-contract.md` (Sanctum Bearer, `{ "data": ... }` envelope, error codes 401/403/404/409/422).
- `exam_demo_web/routes/api.php` and `app/Http/Controllers/Api/` **do not exist yet** — create both when adding the first endpoint; API code goes only there.
- Any request/response change must update `docs/api-contract.md`; breaking change → PR title `feat(api)!: ...` + update Flutter in same/follow-up PR.
- `contract.yml` CI only posts a warning (never fails) when the doc is untouched.

## CI & git

- `.github/workflows/web.yml` triggers only on `exam_demo_web/**`, `app.yml` only on `exam_demo_app/**`, both with `working-directory` set — don't remove the `paths` filters.
- `main` is protected: PR + `ci` checks green + 1 approval, squash merge, delete branch.
- Branches: `feat/app-*`, `fix/app-*`, `feat/web-*`, `feat/api-*`. Commits: `feat(app|web|api): ...`, `fix(...)`, `chore(ci): ...`.
- Tags are independent: `app-v*`, `web-v*`.
- `CODEOWNERS` still has placeholder `@mobile-team`/`@backend-team` — replace with real usernames; `Api/**` and `docs/api-contract.md` require both teams.
