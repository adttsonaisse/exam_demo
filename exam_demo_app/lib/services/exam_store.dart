import 'package:flutter/foundation.dart';

import '../models/exam_models.dart';

/// Mode pemuatan daftar ujian, termasuk pratinjau kosong dan galat
/// untuk memastikan tiap status layar bisa diverifikasi.
enum ExamLoadMode { normal, kosong, galat }

/// Kunci jawaban contoh untuk menghitung nilai di sisi klien demo.
/// Di produksi nilai dihitung backend saat POST submit.
const Map<int, Map<int, String>> _kunciContoh = {
  1: {1: 'B', 2: 'C', 3: 'A', 4: 'D', 5: 'B'},
  2: {6: 'A', 7: 'D', 8: 'C', 9: 'B', 10: 'A'},
  3: {11: 'C', 12: 'A', 13: 'D', 14: 'B', 15: 'C'},
};

List<Question> _soalContoh(int ujianId) {
  final kunci = _kunciContoh[ujianId] ?? _kunciContoh[1]!;
  const bank = {
    1: 'Hasil dari 12 + 8 x 2 adalah ...',
    2: 'Bentuk sederhana dari 3/4 + 1/2 adalah ...',
    3: 'Akar dari 144 adalah ...',
    4: 'Keliling persegi dengan sisi 9 cm adalah ...',
    5: 'Nilai x dari 2x + 6 = 18 adalah ...',
    6: 'Ibukota provinsi Jawa Barat adalah ...',
    7: 'Peristiwa Rengasdengklok terjadi pada tahun ...',
    8: 'Sungai terpanjang di Indonesia adalah ...',
    9: 'Lambang sila ketiga Pancasila adalah ...',
    10: 'Presiden pertama Indonesia adalah ...',
    11: 'Satuan gaya dalam SI adalah ...',
    12: 'Alat ukur tegangan listrik adalah ...',
    13: 'Rumus kecepatan adalah ...',
    14: 'Benda yang dapat ditarik magnet disebut ...',
    15: 'Warna lakmus merah dalam larutan basa menjadi ...',
  };
  const opsi = ['A. Pilihan pertama', 'B. Pilihan kedua', 'C. Pilihan ketiga', 'D. Pilihan keempat'];
  return kunci.keys.map((id) {
    return Question(id: id, teks: bank[id] ?? 'Soal nomor $id', opsi: opsi);
  }).toList();
}

/// Status sesi ujian aktif beserta jawaban dan antrean offline.
class ExamStore extends ChangeNotifier {
  bool isLoading = false;
  String? error;
  Siswa? siswa;
  List<ExamInfo> exams = [];
  ExamInfo? ujianAktif;
  List<Question> soalAktif = [];
  Map<int, String> jawaban = {};
  int indeksSoal = 0;
  ExamResult? lastResult;

  /// Antrean lokal: jawaban dan event yang menunggu koneksi.
  final List<QueuedAnswer> outbox = [];

  /// Sakelar demo mode offline untuk membuktikan antrean lokal.
  bool offlineMode = false;

  String? teacherToken;
  DateTime? teacherTokenExpiry;

  bool get isLoggedIn => siswa != null;
  int get terjawab => jawaban.length;
  int get antrean => outbox.length;

  List<IntegrityCheck> get integrityChecks => const [
        IntegrityCheck(
          nama: 'Screenshot dan rekam layar diblokir',
          keterangan: 'Aktif selama ujian, pelanggaran dicatat',
          lolos: true,
        ),
        IntegrityCheck(
          nama: 'Jam perangkat normal',
          keterangan: 'Tidak terdeteksi pemunduran jam',
          lolos: true,
        ),
        IntegrityCheck(
          nama: 'Perangkat lolos cek awal',
          keterangan: 'Bukan emulator, tidak di-root, lokasi asli',
          lolos: true,
        ),
        IntegrityCheck(
          nama: 'Panggilan telepon',
          keterangan: 'Ujian dijeda dan dicatat saat ada panggilan',
          lolos: true,
        ),
      ];

  Future<bool> login(String nisn, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (nisn == '0000000000') {
      isLoading = false;
      error = 'NISN tidak terdaftar. Periksa kembali 10 digit NISN kamu.';
      notifyListeners();
      return false;
    }
    siswa = Siswa(id: 1, nama: 'Siswa Demo', kelas: 'XII-1');
    isLoading = false;
    notifyListeners();
    return true;
  }

  void logout() {
    siswa = null;
    exams = [];
    resetSesi();
    notifyListeners();
  }

  Future<void> loadExams([ExamLoadMode mode = ExamLoadMode.normal]) async {
    isLoading = true;
    error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    switch (mode) {
      case ExamLoadMode.kosong:
        exams = [];
      case ExamLoadMode.galat:
        error = 'Daftar ujian gagal dimuat. Periksa koneksi lalu coba lagi.';
        exams = [];
      case ExamLoadMode.normal:
        exams = const [
          ExamInfo(
            id: 1,
            mapel: 'Matematika',
            durasiMenit: 90,
            status: ExamStatus.belumMulai,
            jumlahSoal: 5,
          ),
          ExamInfo(
            id: 2,
            mapel: 'Sejarah Indonesia',
            durasiMenit: 60,
            status: ExamStatus.sedangBerjalan,
            jumlahSoal: 5,
          ),
          ExamInfo(
            id: 3,
            mapel: 'Fisika',
            durasiMenit: 90,
            status: ExamStatus.selesai,
            jumlahSoal: 5,
            nilai: 80,
          ),
        ];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> startExam(ExamInfo exam) async {
    isLoading = true;
    error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    ujianAktif = exam;
    soalAktif = _soalContoh(exam.id);
    jawaban = {};
    indeksSoal = 0;
    lastResult = null;
    isLoading = false;
    notifyListeners();
  }

  void pindahSoal(int indeks) {
    if (indeks < 0 || indeks >= soalAktif.length) return;
    indeksSoal = indeks;
    notifyListeners();
  }

  void jawab(int soalId, String opsi) {
    jawaban[soalId] = opsi;
    final ujianId = ujianAktif?.id ?? 0;
    outbox.add(
      QueuedAnswer(
        ujianId: ujianId,
        soalId: soalId,
        opsi: opsi,
        dicatatPada: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Menerbitkan token guru demo sekali pakai 5 menit.
  /// Di produksi token diterbitkan perangkat guru atau backend.
  String issueTeacherToken() {
    final now = DateTime.now();
    teacherToken = 'GURU-${now.minute}${now.second}';
    teacherTokenExpiry = now.add(const Duration(minutes: 5));
    notifyListeners();
    return teacherToken!;
  }

  /// Mengumpulkan jawaban. Tanpa pengumpulan otomatis dari sistem:
  /// hanya dipanggil dari tombol Kumpulkan milik siswa.
  ExamResult submit() {
    final exam = ujianAktif;
    if (exam == null) {
      throw StateError('Tidak ada ujian aktif');
    }
    final kunci = _kunciContoh[exam.id] ?? const {};
    var benar = 0;
    for (final soal in soalAktif) {
      final kunciJawaban = kunci[soal.id];
      final isi = jawaban[soal.id];
      if (isi != null && kunciJawaban != null && isi.startsWith(kunciJawaban)) {
        benar++;
      }
    }
    final nilai = soalAktif.isEmpty
        ? 0
        : ((benar / soalAktif.length) * 100).round();
    lastResult = ExamResult(
      ujianId: exam.id,
      mapel: exam.mapel,
      nilai: nilai,
      jumlahBenar: benar,
      jumlahSoal: soalAktif.length,
    );
    if (!offlineMode) {
      outbox.clear();
    }
    notifyListeners();
    return lastResult!;
  }

  void resetSesi() {
    ujianAktif = null;
    soalAktif = [];
    jawaban = {};
    indeksSoal = 0;
    teacherToken = null;
    teacherTokenExpiry = null;
    notifyListeners();
  }
}
