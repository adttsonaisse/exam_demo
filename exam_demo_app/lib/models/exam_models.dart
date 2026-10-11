/// Model data ujian. Bentuk JSON mengikuti docs/api-contract.md.
library;

class Siswa {
  const Siswa({required this.id, required this.nama, required this.kelas});

  factory Siswa.fromJson(Map<String, dynamic> json) => Siswa(
        id: json['id'] as int,
        nama: json['nama'] as String,
        kelas: json['kelas'] as String,
      );

  final int id;
  final String nama;
  final String kelas;
}

enum ExamStatus { belumMulai, sedangBerjalan, selesai }

extension ExamStatusLabel on ExamStatus {
  String get label => switch (this) {
        ExamStatus.belumMulai => 'Belum mulai',
        ExamStatus.sedangBerjalan => 'Berlangsung',
        ExamStatus.selesai => 'Selesai',
      };

  static ExamStatus fromApi(String value) => switch (value) {
        'berlangsung' => ExamStatus.sedangBerjalan,
        'selesai' => ExamStatus.selesai,
        _ => ExamStatus.belumMulai,
      };
}

class ExamInfo {
  const ExamInfo({
    required this.id,
    required this.mapel,
    required this.durasiMenit,
    required this.status,
    required this.jumlahSoal,
    this.nilai,
  });

  final int id;
  final String mapel;
  final int durasiMenit;
  final ExamStatus status;
  final int jumlahSoal;
  final int? nilai;
}

class Question {
  const Question({required this.id, required this.teks, required this.opsi});

  final int id;
  final String teks;
  final List<String> opsi;
}

class ExamResult {
  const ExamResult({
    required this.ujianId,
    required this.mapel,
    required this.nilai,
    required this.jumlahBenar,
    required this.jumlahSoal,
  });

  final int ujianId;
  final String mapel;
  final int nilai;
  final int jumlahBenar;
  final int jumlahSoal;
}

/// Satu jawaban yang antre di perangkat saat offline.
class QueuedAnswer {
  const QueuedAnswer({
    required this.ujianId,
    required this.soalId,
    required this.opsi,
    required this.dicatatPada,
  });

  final int ujianId;
  final int soalId;
  final String opsi;
  final DateTime dicatatPada;
}

/// Hasil cek integritas perangkat pada layar pra-ujian.
class IntegrityCheck {
  const IntegrityCheck({
    required this.nama,
    required this.keterangan,
    required this.lolos,
  });

  final String nama;
  final String keterangan;
  final bool lolos;
}
