# Kontrak API — Flutter (siswa) ↔ Laravel

Sumber kebenaran untuk semua endpoint yang dipakai app ujian siswa.
Dashboard **guru** (rekap nilai) dan **admin** (monitoring) murni Livewire/Blade di `exam_demo_web/` dan **tidak** lewat API ini.

> Aturan: ubah request/response di `exam_demo_web/routes/api.php` atau `exam_demo_web/app/Http/Controllers/Api/**`
> wajib update file ini + judul PR `feat(api)!: ...` kalau breaking.

## Konvensi umum

- Base URL: `https://<host>/api` (lokal: `http://localhost:8000/api`).
- Auth: Laravel Sanctum Bearer token. Header `Authorization: Bearer <token>`, `Accept: application/json`.
- Format sukses:
  ```json
  { "data": {} }
  ```
- Format error:
  ```json
  { "message": "...", "errors": { "field": ["..."] } }
  ```
- Kode error: `401` token invalid, `403` bukan siswa / bukan peserta ujian, `404` ujian tidak ditemukan, `409` ujian sudah dikumpulkan / waktu habis, `422` validasi.

## Endpoint (draft — sesuaikan saat implementasi)

### 1. Login siswa
`POST /api/login`
```json
{ "nisn": "123456", "password": "secret" }
```
→ `200 { "data": { "token": "...", "siswa": { "id": 1, "nama": "...", "kelas": "XII-1" } } }`

### 2. Daftar ujian tersedia
`GET /api/ujian`
→ `200 { "data": [{ "id": 1, "mapel": "Matematika", "durasi_menit": 90, "status": "belum_mulai" }] }`

### 3. Mulai ujian
`POST /api/ujian/{id}/start`
→ `200 { "data": { "sesi_id": 10, "berakhir_pada": "2026-10-11T09:30:00Z", "soal": [{ "id": 1, "teks": "...", "opsi": ["A","B","C","D"] }] } }`
→ `409` jika sudah pernah dikumpulkan.

### 4. Submit jawaban
`POST /api/ujian/{id}/submit`
```json
{ "sesi_id": 10, "jawaban": [{ "soal_id": 1, "opsi": "B" }] }
```
→ `200 { "data": { "nilai": 85, "jumlah_benar": 17, "jumlah_soal": 20 } }`

### 5. Nilai saya
`GET /api/nilai`
→ `200 { "data": [{ "ujian_id": 1, "mapel": "Matematika", "nilai": 85 }] }`

## Checklist breaking change
- [ ] Field dihapus / diganti nama / tipe berubah?
- [ ] Status code berubah?
- [ ] Auth berubah?
- [ ] Flutter (`exam_demo_app/`) diupdate bareng?

## Yang bukan API (Livewire saja)
- Rekap nilai per kelas/mapel → dashboard guru di web.
- Monitoring live (siapa sedang ujian, sisa waktu, submit masuk) → dashboard admin di web.
