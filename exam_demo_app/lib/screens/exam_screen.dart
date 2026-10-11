import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/exam_models.dart';
import '../services/violation_service.dart';
import '../theme/stripe_theme.dart';
import '../widgets/stripe_widgets.dart';
import 'locked_screen.dart';
import 'result_screen.dart';

/// Layar ujian: soal, opsi 44px, timer, dan pengawas pelanggaran.
/// Catatan: tombol kembali sistem tidak keluar dari ujian, hanya
/// dicatat sebagai log senyap bila ditekan berulang.
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key, required this.exam});

  final ExamInfo exam;

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> with WidgetsBindingObserver {
  Timer? _detik;
  late int _sisaDetik;
  DateTime _tampilSoalPada = DateTime.now();
  DateTime _interaksiTerakhir = DateTime.now();
  DateTime? _jedaPada;
  bool _peringatanTampil = false;
  ViolationKind? _pelanggaranTerakhir;

  static const MethodChannel _telepon =
      MethodChannel('exam_demo/phone_call');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sisaDetik = widget.exam.durasiMenit * 60;
    _telepon.setMethodCallHandler(_panggilanMasuk);
    _detik = Timer.periodic(const Duration(seconds: 1), _tiapDetik);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detik?.cancel();
    _telepon.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _panggilanMasuk(MethodCall call) async {
    if (call.method == 'teleponMasuk' && mounted) {
      final violations = AppScope.of(context).violations;
      violations.recordPhoneCall();
      setState(() => _jedaPada = DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Panggilan masuk. Ujian dijeda, lanjutkan setelah selesai.'),
        ),
      );
    }
  }

  void _tiapDetik(Timer timer) {
    if (!mounted || _jedaPada != null) return;
    final violations = AppScope.of(context).violations;
    setState(() => _sisaDetik = _sisaDetik > 0 ? _sisaDetik - 1 : 0);
    violations.recordIdle(DateTime.now().difference(_interaksiTerakhir));
    if (_sisaDetik == 0) {
      timer.cancel();
      _waktuHabis();
    }
  }

  /// Pindah aplikasi terdeteksi lewat lifecycle. Kembali dalam
  /// 3 detik masih aman, lebih dari itu pelanggaran berat.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final violations = AppScope.of(context).violations;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _jedaPada = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final jeda = _jedaPada;
      _jedaPada = null;
      if (jeda != null &&
          DateTime.now().difference(jeda) > const Duration(seconds: 3)) {
        _catatBerat(violations, ViolationKind.appSwitch);
      }
    }
  }

  void _catatBerat(ViolationService violations, ViolationKind kind) {
    if (!mounted || violations.isLocked) return;
    violations.recordHeavy(kind);
    setState(() {
      _pelanggaranTerakhir = kind;
      _peringatanTampil = true;
    });
    if (violations.isLocked) {
      _bukaKunci();
    }
  }

  void _bukaKunci() {
    setState(() => _peringatanTampil = false);
    final scope = AppScope.of(context);
    final token = scope.store.issueTeacherToken();
    scope.violations.issueTeacherToken(token, const Duration(minutes: 5));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LockedScreen(
          exam: widget.exam,
          alasan: scope.violations.lockReason ?? 'Batas pelanggaran tercapai',
        ),
      ),
    );
  }

  void _jawab(String opsi, int soalId) {
    final scope = AppScope.of(context);
    final now = DateTime.now();
    scope.violations.recordAnswerTiming(now.difference(_tampilSoalPada));
    scope.store.jawab(soalId, opsi);
    setState(() {
      _interaksiTerakhir = now;
      _tampilSoalPada = now;
    });
  }

  void _pindah(int indeks) {
    AppScope.of(context).store.pindahSoal(indeks);
    setState(() {
      _interaksiTerakhir = DateTime.now();
      _tampilSoalPada = DateTime.now();
    });
  }

  void _waktuHabis() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StripeRadius.dialog),
        ),
        title: const Text('Waktu habis'),
        content: const Text(
          'Waktu ujian selesai. Kumpulkan jawaban sekarang. Sistem tidak mengumpulkan otomatis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Periksa Lagi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _kumpulkan();
            },
            child: const Text('Kumpulkan'),
          ),
        ],
      ),
    );
  }

  void _konfirmasiKumpul() {
    final store = AppScope.of(context).store;
    final belum = store.soalAktif.length - store.terjawab;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StripeRadius.dialog),
        ),
        title: const Text('Kumpulkan jawaban?'),
        content: Text(
          belum == 0
              ? 'Semua soal sudah dijawab. Nilai langsung dihitung.'
              : 'Masih ada $belum soal belum dijawab. Soal kosong dihitung salah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _kumpulkan();
            },
            child: const Text('Kumpulkan'),
          ),
        ],
      ),
    );
  }

  void _kumpulkan() {
    final store = AppScope.of(context).store;
    final hasil = store.submit();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResultScreen(hasil: hasil)),
    );
  }

  String get _labelWaktu {
    final jam = _sisaDetik ~/ 3600;
    final menit = (_sisaDetik % 3600) ~/ 60;
    final detik = _sisaDetik % 60;
    final mm = menit.toString().padLeft(2, '0');
    final ss = detik.toString().padLeft(2, '0');
    return jam > 0 ? '$jam:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        scope.violations.recordBackPress();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tombol kembali dikunci selama ujian. Pakai navigasi nomor soal.',
            ),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.exam.mapel),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SecureBadge()),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: Listenable.merge([scope.store, scope.violations]),
          builder: (context, _) {
            final store = scope.store;
            if (store.soalAktif.isEmpty) {
              return const Center(
                child: Text('Soal belum siap. Kembali lalu mulai ulang.'),
              );
            }
            final soal = store.soalAktif[store.indeksSoal];
            final dipilih = store.jawaban[soal.id];
            return Stack(
              children: [
                Column(
                  children: [
                    _HeaderUjian(
                      sisa: _labelWaktu,
                      terjawab: store.terjawab,
                      total: store.soalAktif.length,
                      count: scope.violations.count,
                      antrean: store.antrean,
                      offline: store.offlineMode,
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          StripeCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Soal ${store.indeksSoal + 1} dari ${store.soalAktif.length}',
                                  style: const TextStyle(
                                    color: StripeColors.body,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  soal.teks,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...soal.opsi.map(
                                  (opsi) => _OpsiJawaban(
                                    opsi: opsi,
                                    dipilih: dipilih == opsi,
                                    onTap: () => _jawab(opsi, soal.id),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _NavigasiSoal(
                            total: store.soalAktif.length,
                            aktif: store.indeksSoal,
                            terjawab: store.jawaban,
                            soal: store.soalAktif,
                            onPindah: _pindah,
                          ),
                          const SizedBox(height: 16),
                          StripeDangerButton(
                            label: 'Kumpulkan',
                            onPressed: _konfirmasiKumpul,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_peringatanTampil && _pelanggaranTerakhir != null)
                  _OverlayPeringatan(
                    kind: _pelanggaranTerakhir!,
                    count: scope.violations.count,
                    onKembali: () =>
                        setState(() => _peringatanTampil = false),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderUjian extends StatelessWidget {
  const _HeaderUjian({
    required this.sisa,
    required this.terjawab,
    required this.total,
    required this.count,
    required this.antrean,
    required this.offline,
  });

  final String sisa;
  final int terjawab;
  final int total;
  final int count;
  final int antrean;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: StripeColors.hairline)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: StripeColors.ink),
          const SizedBox(width: 6),
          Text(
            sisa,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(StripeRadius.control),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : terjawab / total,
                minHeight: 6,
                backgroundColor: StripeColors.bone,
                color: StripeColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ViolationCounter(count: count, max: maxViolations),
          if (offline || antrean > 0)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: StripeBadge(
                label: offline ? 'Offline $antrean' : 'Antre $antrean',
              ),
            ),
        ],
      ),
    );
  }
}

class _OpsiJawaban extends StatelessWidget {
  const _OpsiJawaban({
    required this.opsi,
    required this.dipilih,
    required this.onTap,
  });

  final String opsi;
  final bool dipilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RadioGroup<String>(
        groupValue: dipilih ? opsi : null,
        onChanged: (_) => onTap(),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(StripeRadius.control),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: dipilih
                  ? StripeColors.primary.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(StripeRadius.control),
              border: Border.all(
                color: dipilih ? StripeColors.primary : StripeColors.hairline,
                width: dipilih ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Radio<String>(value: opsi),
                Expanded(
                  child: Text(opsi, style: const TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigasiSoal extends StatelessWidget {
  const _NavigasiSoal({
    required this.total,
    required this.aktif,
    required this.terjawab,
    required this.soal,
    required this.onPindah,
  });

  final int total;
  final int aktif;
  final Map<int, String> terjawab;
  final List<Question> soal;
  final ValueChanged<int> onPindah;

  @override
  Widget build(BuildContext context) {
    return StripeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nomor soal',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(total, (i) {
              final sudah = terjawab.containsKey(soal[i].id);
              final kini = i == aktif;
              return SizedBox(
                width: 48,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => onPindah(i),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: EdgeInsets.zero,
                    backgroundColor: kini
                        ? StripeColors.primary
                        : (sudah
                            ? StripeColors.successWash
                            : Colors.white),
                    foregroundColor:
                        kini ? Colors.white : StripeColors.ink,
                    side: BorderSide(
                      color: kini
                          ? StripeColors.primary
                          : (sudah
                              ? StripeColors.success
                              : StripeColors.hairline),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(StripeRadius.control),
                    ),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _OverlayPeringatan extends StatelessWidget {
  const _OverlayPeringatan({
    required this.kind,
    required this.count,
    required this.onKembali,
  });

  final ViolationKind kind;
  final int count;
  final VoidCallback onKembali;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: StripeColors.overlay,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(StripeRadius.dialog),
            border: Border.all(color: StripeColors.danger, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.warning,
                color: StripeColors.danger,
                size: 40,
                semanticLabel: 'Peringatan pelanggaran',
              ),
              const SizedBox(height: 12),
              Text(
                'Pelanggaran $count dari $maxViolations',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: StripeColors.dangerText,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kind.label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Satu kali lagi layar terkunci dan butuh token guru. Jawaban yang sudah diisi tetap tersimpan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: StripeColors.body,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              StripeButton(label: 'Kembali ke Soal', onPressed: onKembali),
            ],
          ),
        ),
      ),
    );
  }
}
