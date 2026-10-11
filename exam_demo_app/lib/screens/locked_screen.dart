import 'package:flutter/material.dart';

import '../main.dart';
import '../models/exam_models.dart';
import '../theme/stripe_theme.dart';
import '../widgets/stripe_widgets.dart';
import 'exam_list_screen.dart';
import 'exam_screen.dart';
import 'result_screen.dart';

/// Layar terkunci: butuh token guru sekali pakai 5 menit.
/// Tidak ada pengumpulan otomatis, draf jawaban tetap aman.
class LockedScreen extends StatefulWidget {
  const LockedScreen({super.key, required this.exam, required this.alasan});

  final ExamInfo exam;
  final String alasan;

  @override
  State<LockedScreen> createState() => _LockedScreenState();
}

class _LockedScreenState extends State<LockedScreen> {
  final _tokenController = TextEditingController();
  String? _galat;
  bool _tampilkanDemo = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _buka() {
    final scope = AppScope.of(context);
    final ok =
        scope.violations.unlockWithToken(_tokenController.text.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ExamScreen(exam: widget.exam)),
      );
    } else {
      setState(() {
        _galat =
            'Token salah, kedaluwarsa, atau sudah dipakai. Minta token baru ke pengawas.';
      });
    }
  }

  void _akhiri() {
    final hasil = AppScope.of(context).store.submit();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResultScreen(hasil: hasil)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      backgroundColor: StripeColors.canvas,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([scope.store, scope.violations]),
          builder: (context, _) {
            final store = scope.store;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                const Icon(
                  Icons.lock,
                  size: 48,
                  color: StripeColors.danger,
                  semanticLabel: 'Ujian terkunci',
                ),
                const SizedBox(height: 16),
                Text(
                  'Ujian Terkunci',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tiga pelanggaran berat tercatat. Pelanggaran terakhir: ${widget.alasan}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: StripeColors.body,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                StripeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Draf kamu aman',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${store.terjawab} dari ${store.soalAktif.length} soal sudah dijawab '
                        'dan tersimpan di perangkat ini. Sistem tidak mengumpulkan otomatis.',
                        style: const TextStyle(
                          color: StripeColors.body,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StripeCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Lanjut dengan token guru',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Minta token sekali pakai ke pengawas. Token berlaku 5 menit untuk satu kali buka.',
                        style: TextStyle(
                          color: StripeColors.body,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_galat != null) ...[
                        StripeAlert(message: _galat!),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        key: const Key('tokenField'),
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Token guru',
                          hintText: 'Contoh: GURU-1234',
                          prefixIcon: Icon(Icons.key),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _buka(),
                      ),
                      const SizedBox(height: 12),
                      StripeButton(
                        label: 'Buka dengan Token Guru',
                        onPressed: _buka,
                      ),
                      TextButton(
                        onPressed: () => setState(
                          () => _tampilkanDemo = !_tampilkanDemo,
                        ),
                        child: Text(
                          _tampilkanDemo
                              ? 'Sembunyikan token demo'
                              : 'Saya pengawas: tampilkan token demo',
                        ),
                      ),
                      if (_tampilkanDemo)
                        StripeAlert(
                          message:
                              'Mode demo: token ${store.teacherToken ?? '-'} '
                              'berlaku sampai ${store.teacherTokenExpiry ?? '-'}. '
                              'Di produksi token hanya ada di perangkat guru.',
                          success: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                StripeGhostButton(
                  label: 'Akhiri dan Kumpulkan Sekarang',
                  onPressed: _akhiri,
                ),
                TextButton(
                  onPressed: () {
                    store.resetSesi();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const ExamListScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Keluar ke Daftar Ujian'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
