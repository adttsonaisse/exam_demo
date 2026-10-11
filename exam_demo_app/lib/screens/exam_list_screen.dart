import 'package:flutter/material.dart';

import '../main.dart';
import '../models/exam_models.dart';
import '../services/exam_store.dart';
import '../theme/stripe_theme.dart';
import '../widgets/stripe_widgets.dart';
import 'pre_exam_screen.dart';

/// Daftar ujian milik siswa: loading skeleton, kosong mengajar, galat.
class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).store.loadExams();
    });
  }

  Future<void> _buka(ExamInfo exam) async {
    final store = AppScope.of(context).store;
    await store.startExam(exam);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PreExamScreen(exam: exam)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      backgroundColor: StripeColors.canvas,
      appBar: AppBar(
        title: const Text('Daftar Ujian'),
        actions: [
          PopupMenuButton<ExamLoadMode>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Pratinjau tampilan',
            onSelected: (mode) => scope.store.loadExams(mode),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ExamLoadMode.normal,
                child: Text('Muat ulang'),
              ),
              PopupMenuItem(
                value: ExamLoadMode.kosong,
                child: Text('Pratinjau kosong'),
              ),
              PopupMenuItem(
                value: ExamLoadMode.galat,
                child: Text('Pratinjau galat'),
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: scope.store,
        builder: (context, _) {
          final store = scope.store;
          if (store.isLoading) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, _) => const SkeletonRow(),
            );
          }
          if (store.error != null) {
            return _Galat(
              message: store.error!,
              onRetry: () => store.loadExams(),
            );
          }
          if (store.exams.isEmpty) {
            return _Kosong(onRetry: () => store.loadExams());
          }
          return RefreshIndicator(
            color: StripeColors.primary,
            onRefresh: () => store.loadExams(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: store.exams.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    'Halo, ${store.siswa?.nama ?? 'Siswa'} (${store.siswa?.kelas ?? ''}). Pilih ujian lalu baca tata tertib sebelum mulai.',
                    style: const TextStyle(
                      color: StripeColors.body,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  );
                }
                final exam = store.exams[index - 1];
                return _KartuUjian(exam: exam, onOpen: () => _buka(exam));
              },
            ),
          );
        },
      ),
    );
  }
}

class _KartuUjian extends StatelessWidget {
  const _KartuUjian({required this.exam, required this.onOpen});

  final ExamInfo exam;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final selesai = exam.status == ExamStatus.selesai;
    return StripeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exam.mapel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StripeBadge(
                label: exam.status.label,
                danger: exam.status == ExamStatus.sedangBerjalan,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${exam.jumlahSoal} soal, ${exam.durasiMenit} menit'
            '${exam.nilai != null ? ', nilai kamu ${exam.nilai}' : ''}',
            style: const TextStyle(color: StripeColors.body, fontSize: 14),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: selesai
                ? StripeGhostButton(
                    label: 'Lihat Nilai',
                    onPressed: onOpen,
                  )
                : StripeButton(
                    label: exam.status == ExamStatus.sedangBerjalan
                        ? 'Lanjutkan Ujian'
                        : 'Lihat Tata Tertib',
                    onPressed: onOpen,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Kosong extends StatelessWidget {
  const _Kosong({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 48,
              color: StripeColors.stone,
              semanticLabel: 'Tidak ada ujian',
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada ujian untuk kamu',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Guru belum menjadwalkan ujian di kelasmu. Tanya wali kelas jika temanmu sudah dapat jadwal tapi kamu belum.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: StripeColors.body,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            StripeGhostButton(label: 'Muat Ulang', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _Galat extends StatelessWidget {
  const _Galat({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StripeAlert(message: message),
            const SizedBox(height: 16),
            StripeButton(label: 'Coba Lagi', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
