import 'package:flutter/material.dart';

import '../main.dart';
import '../models/exam_models.dart';
import '../theme/stripe_theme.dart';
import '../widgets/stripe_widgets.dart';
import 'exam_list_screen.dart';

/// Layar hasil: nilai dan jumlah jawaban benar.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.hasil});

  final ExamResult hasil;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final lulus = hasil.nilai >= 70;
    return Scaffold(
      appBar: AppBar(title: const Text('Nilai Saya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StripeCard(
            child: Column(
              children: [
                StripeBadge(
                  label: lulus ? 'Tuntas' : 'Belum tuntas',
                  danger: !lulus,
                ),
                const SizedBox(height: 12),
                Text(
                  '${hasil.nilai}',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: StripeColors.ink,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasil.mapel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Benar ${hasil.jumlahBenar} dari ${hasil.jumlahSoal} soal',
                  style: const TextStyle(
                    color: StripeColors.body,
                    fontSize: 14,
                  ),
                ),
                if (store.offlineMode && store.antrean > 0) ...[
                  const SizedBox(height: 12),
                  StripeAlert(
                    message:
                        'Mode offline: ${store.antrean} jawaban masih antre di perangkat dan akan dikirim saat koneksi kembali.',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          StripeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan pengawas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                ListenableBuilder(
                  listenable: store,
                  builder: (context, _) {
                    final violations = AppScope.of(context).violations;
                    return ListenableBuilder(
                      listenable: violations,
                      builder: (context, _) {
                        if (violations.events.isEmpty &&
                            violations.silentLog.isEmpty) {
                          return const Text(
                            'Ujian berjalan bersih tanpa catatan.',
                            style: TextStyle(
                              color: StripeColors.body,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pelanggaran berat: ${violations.events.length}. '
                              'Catatan ringan: ${violations.silentLog.length}.',
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StripeButton(
            label: 'Kembali ke Daftar Ujian',
            onPressed: () {
              store.resetSesi();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ExamListScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
