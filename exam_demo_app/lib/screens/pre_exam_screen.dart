import 'package:flutter/material.dart';

import '../main.dart';
import '../models/exam_models.dart';
import '../theme/stripe_theme.dart';
import '../widgets/stripe_widgets.dart';
import 'exam_screen.dart';

/// Tujuh larangan berat yang masing-masing menaikkan counter 1 sampai 3.
const List<String> laranganBerat = [
  'Pindah aplikasi lebih dari 3 detik.',
  'Membuka daftar aplikasi terakhir.',
  'Mengaktifkan layar belah atau multi jendela.',
  'Membuka jendela melayang, PiP, atau bubble chat.',
  'Membuka bilah status atau notifikasi.',
  'Mematikan atau mengunci layar.',
  'Login akun yang sama di perangkat lain.',
];

/// Layar pra-ujian: tata tertib, persetujuan pencatatan, cek perangkat.
class PreExamScreen extends StatefulWidget {
  const PreExamScreen({super.key, required this.exam});

  final ExamInfo exam;

  @override
  State<PreExamScreen> createState() => _PreExamScreenState();
}

class _PreExamScreenState extends State<PreExamScreen> {
  bool _setuju = false;

  void _mulai() {
    if (!_setuju) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ExamScreen(exam: widget.exam)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final checks = store.integrityChecks;
    final semuaLolos = checks.every((c) => c.lolos);
    return Scaffold(
      appBar: AppBar(title: Text('Persiapan ${widget.exam.mapel}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StripeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tata tertib ${widget.exam.mapel}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.exam.jumlahSoal} soal, ${widget.exam.durasiMenit} menit. '
                  'Tujuh tindakan di bawah ini adalah pelanggaran berat. '
                  'Setiap pelanggaran membunyikan alarm dan menaikkan '
                  'penghitung. Tiga kali berarti layar terkunci.',
                  style: const TextStyle(
                    color: StripeColors.body,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                ...laranganBerat.map(
                  (larangan) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: StripeColors.dangerWash,
                            borderRadius: BorderRadius.circular(
                              StripeRadius.control,
                            ),
                          ),
                          child: Text(
                            '${laranganBerat.indexOf(larangan) + 1}',
                            style: const TextStyle(
                              color: StripeColors.dangerText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            larangan,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StripeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kondisi perangkat',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StripeBadge(
                      label: semuaLolos ? 'Siap' : 'Periksa',
                      danger: !semuaLolos,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...checks.map(
                  (check) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          check.lolos
                              ? Icons.check_circle
                              : Icons.warning,
                          size: 18,
                          color: check.lolos
                              ? StripeColors.successText
                              : StripeColors.dangerText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                check.nama,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                check.keterangan,
                                style: const TextStyle(
                                  color: StripeColors.body,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StripeCard(
            child: CheckboxListTile(
              value: _setuju,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Saya setuju aktivitas ujian dicatat',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Jawaban, perpindahan aplikasi, dan penguncian layar dicatat untuk pengawas. Panggilan masuk hanya menjeda, bukan pelanggaran.',
                style: TextStyle(
                  color: StripeColors.body,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              activeColor: StripeColors.primary,
              onChanged: (value) => setState(() => _setuju = value ?? false),
            ),
          ),
          const SizedBox(height: 16),
          StripeButton(
            label: 'Mulai Ujian',
            onPressed: _setuju ? _mulai : null,
          ),
          if (!_setuju)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Centang persetujuan dulu agar tombol Mulai Ujian aktif.',
                textAlign: TextAlign.center,
                style: TextStyle(color: StripeColors.body, fontSize: 12),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
