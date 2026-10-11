# Branch protection — `main`

Diatur manual di GitHub (tidak bisa via file). Setelah push repo ke GitHub:

1. Buka repo → Settings → Branches → Add classic branch protection rule.
2. Branch name pattern: `main`.
3. Centang:
   - Require a pull request before merging (required approvals: 1)
   - Dismiss stale pull request approvals when new commits are pushed
   - Require status checks before merging → pilih `ci` dari `web` dan `app`
   - Do not allow bypassing the above settings
4. Jangan centang "Allow force pushes" / "Allow deletions".

Verifikasi: push langsung ke `main` harus ditolak, perubahan hanya lewat PR.
