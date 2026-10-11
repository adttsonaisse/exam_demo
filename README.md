# exam_demo — Monorepo Ujian

Satu repo, dua deployable:

| Folder | Stack | Peran |
|---|---|---|
| `exam_demo_app/` | Flutter | App ujian **siswa** (login, kerjakan soal, submit) |
| `exam_demo_web/` | Laravel 13 + Livewire | **API** untuk Flutter + dashboard **guru** (rekap nilai) + **admin** (monitoring ujian) |

Kontrak API: `docs/api-contract.md`.

## Cara jalan lokal

### Web (Laravel)
```bash
cd exam_demo_web
composer setup   # install + key + migrate + build
composer dev     # server + queue + vite
```

### App (Flutter)
```bash
cd exam_demo_app
flutter pub get
flutter run
```

## Flow GitHub

- Branch utama: `main` (protected, wajib PR + CI hijau).
- Branch kerja pendek dari `main`:
  - `feat/app-*`, `fix/app-*` → Flutter siswa
  - `feat/web-*`, `fix/web-*` → dashboard guru/admin
  - `feat/api-*` → endpoint Laravel untuk Flutter
- Commit: `feat(app): ...`, `feat(web): ...`, `feat(api): ...`, `fix(...)`, `chore(ci): ...`. Breaking API: `feat(api)!: ...`.
- Merge: squash via PR, hapus branch.
- CI path-filtered (`.github/workflows/`):
  - ubah `exam_demo_app/**` → hanya `app.yml` jalan
  - ubah `exam_demo_web/**` → hanya `web.yml` jalan
  - ubah `routes/api.php` / `Controllers/Api/**` / `docs/api-contract.md` → `contract.yml` ingatkan cek breaking change
- Tag independen: `app-v*` dan `web-v*`.
- Branch protection (diatur di GitHub UI → Settings → Branches → `main`): require PR + status checks `web`/`app`, 1 approval, no force-push. Lihat `docs/branch-protection.md`.
