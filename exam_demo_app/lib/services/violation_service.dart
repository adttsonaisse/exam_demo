import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Batas jumlah pelanggaran berat sebelum layar terkunci.
const int maxViolations = 3;

/// Pelanggaran berat: memicu alarm visual dan menaikkan counter.
/// Mencapai 3 kali berarti layar TERKUNCI dan butuh token guru.
enum ViolationKind {
  appSwitch,
  recentApps,
  splitScreen,
  floatingWindow,
  statusBar,
  screenOff,
  doubleSession,
}

extension ViolationLabel on ViolationKind {
  String get label => switch (this) {
        ViolationKind.appSwitch =>
          'Pindah aplikasi lebih dari 3 detik',
        ViolationKind.recentApps =>
          'Membuka daftar aplikasi terakhir',
        ViolationKind.splitScreen =>
          'Mengaktifkan layar belah atau multi jendela',
        ViolationKind.floatingWindow =>
          'Membuka jendela melayang, PiP, atau bubble',
        ViolationKind.statusBar =>
          'Membuka bilah status atau notifikasi',
        ViolationKind.screenOff =>
          'Mematikan atau mengunci layar',
        ViolationKind.doubleSession =>
          'Login ganda di perangkat lain',
      };
}

/// Satu kejadian tercatat, berat maupun ringan.
class ViolationEvent {
  ViolationEvent({
    required this.label,
    required this.berat,
    DateTime? waktu,
  }) : waktu = waktu ?? DateTime.now();

  final String label;
  final bool berat;
  final DateTime waktu;
}

/// Layanan anti-contek: counter pelanggaran, kunci, dan token guru.
///
/// Deteksi platform (bilah status, overlay, FLAG_SECURE) lewat
/// [secureChannel]. Selama plugin native belum dipasang, kanal ini
/// adalah stub yang mengembalikan nilai aman dan semua pemicu berat
/// tetap bisa dicatat lewat [recordHeavy] dari AppLifecycle atau tes.
class ViolationService extends ChangeNotifier {
  static const MethodChannel secureChannel = MethodChannel('exam_demo/secure');

  final List<ViolationEvent> _berat = [];
  final List<ViolationEvent> _ringan = [];
  final List<DateTime> _tekanBack = [];
  int _jawabCepatBeruntun = 0;

  String? _tokenGuru;
  DateTime? _tokenBerlakuSampai;
  bool _tokenTerpakai = false;

  int get count => _berat.length;
  bool get isLocked => _berat.length >= maxViolations;
  List<ViolationEvent> get events => List.unmodifiable(_berat);
  List<ViolationEvent> get silentLog => List.unmodifiable(_ringan);

  String? get lockReason => isLocked ? _berat.last.label : null;

  /// Menerbitkan token guru sekali pakai. Di produksi ini dilakukan
  /// perangkat guru atau backend, bukan aplikasi siswa.
  void issueTeacherToken(String token, Duration masaBerlaku) {
    _tokenGuru = token;
    _tokenBerlakuSampai = DateTime.now().add(masaBerlaku);
    _tokenTerpakai = false;
    notifyListeners();
  }

  bool get hasValidToken =>
      _tokenGuru != null &&
      !_tokenTerpakai &&
      _tokenBerlakuSampai != null &&
      DateTime.now().isBefore(_tokenBerlakuSampai!);

  /// Membuka kunci dengan token guru. Token kedaluwarsa dalam
  /// 5 menit dan hanya berlaku satu kali.
  bool unlockWithToken(String token) {
    final expected = _tokenGuru;
    if (expected == null || _tokenTerpakai) return false;
    final expiry = _tokenBerlakuSampai;
    if (expiry == null || DateTime.now().isAfter(expiry)) return false;
    if (token.trim() != expected) return false;
    _tokenTerpakai = true;
    _berat.clear();
    _jawabCepatBeruntun = 0;
    notifyListeners();
    return true;
  }

  /// Mencatat pelanggaran berat: menaikkan counter 1 sampai 3.
  void recordHeavy(ViolationKind kind) {
    if (isLocked) return;
    _berat.add(ViolationEvent(label: kind.label, berat: true));
    notifyListeners();
  }

  /// Mencatat kejadian ringan tanpa alarm: hanya masuk log senyap.
  void recordLight(String label) {
    _ringan.add(ViolationEvent(label: label, berat: false));
    notifyListeners();
  }

  /// Dipanggil tiap jawaban dikirim. Tiga jawaban kilat beruntun
  /// (di bawah 2 detik) dicatat sebagai log senyap.
  void recordAnswerTiming(Duration lamaMenjawab) {
    if (lamaMenjawab < const Duration(seconds: 2)) {
      _jawabCepatBeruntun++;
      if (_jawabCepatBeruntun >= 3) {
        _jawabCepatBeruntun = 0;
        recordLight('Menjawab di bawah 2 detik 3 kali beruntun');
      }
    } else {
      _jawabCepatBeruntun = 0;
    }
  }

  /// Dipanggil saat tidak ada interaksi lebih dari 5 menit.
  void recordIdle(Duration lamaDiam) {
    if (lamaDiam >= const Duration(minutes: 5)) {
      recordLight('Tidak ada interaksi lebih dari 5 menit');
    }
  }

  /// Dipanggil tiap tombol kembali ditekan. Spam tombol kembali
  /// (3 kali dalam 10 detik) hanya dicatat senyap.
  void recordBackPress() {
    final now = DateTime.now();
    _tekanBack.add(now);
    _tekanBack.removeWhere((t) => now.difference(t).inSeconds > 10);
    if (_tekanBack.length >= 3) {
      _tekanBack.clear();
      recordLight('Menekan tombol kembali 3 kali dalam 10 detik');
    }
  }

  /// Telepon masuk: ujian dijeda dan dicatat sebagai info, bukan pelanggaran.
  void recordPhoneCall() {
    recordLight('Panggilan masuk: ujian dijeda sementara');
  }

  void reset() {
    _berat.clear();
    _ringan.clear();
    _tekanBack.clear();
    _jawabCepatBeruntun = 0;
    _tokenGuru = null;
    _tokenBerlakuSampai = null;
    _tokenTerpakai = false;
    notifyListeners();
  }

  /// Stub kanal native. Mengembalikan false untuk semua flag sampai
  /// kode Android (FLAG_SECURE, deteksi overlay, split-screen)
  /// dipasang. Tidak pernah melempar agar UI tetap jalan.
  Future<Map<String, bool>> queryPlatformFlags() async {
    try {
      final result = await secureChannel.invokeMapMethod<String, bool>(
        'queryFlags',
      );
      return Map<String, bool>.from(result ?? const {});
    } on MissingPluginException {
      return const {
        'secureFlag': false,
        'overlayAktif': false,
        'splitScreen': false,
      };
    } on PlatformException {
      return const {
        'secureFlag': false,
        'overlayAktif': false,
        'splitScreen': false,
      };
    }
  }
}
