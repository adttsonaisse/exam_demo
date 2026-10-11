import 'package:exam_demo_app/services/violation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViolationService counter dan kunci', () {
    test('counter naik 0 ke 1 ke 2 tanpa kunci', () {
      final service = ViolationService();
      expect(service.count, 0);
      expect(service.isLocked, isFalse);

      service.recordHeavy(ViolationKind.appSwitch);
      expect(service.count, 1);
      expect(service.isLocked, isFalse);

      service.recordHeavy(ViolationKind.statusBar);
      expect(service.count, 2);
      expect(service.isLocked, isFalse);
    });

    test('pelanggaran ketiga mengunci layar', () {
      final service = ViolationService();
      service.recordHeavy(ViolationKind.appSwitch);
      service.recordHeavy(ViolationKind.statusBar);
      service.recordHeavy(ViolationKind.screenOff);

      expect(service.count, 3);
      expect(service.isLocked, isTrue);
      expect(service.lockReason, isNotNull);
    });

    test('counter tidak naik lagi setelah terkunci', () {
      final service = ViolationService();
      service.recordHeavy(ViolationKind.appSwitch);
      service.recordHeavy(ViolationKind.statusBar);
      service.recordHeavy(ViolationKind.screenOff);
      service.recordHeavy(ViolationKind.recentApps);

      expect(service.count, 3);
    });

    test('token benar membuka kunci dan me-reset counter', () {
      final service = ViolationService();
      service.recordHeavy(ViolationKind.appSwitch);
      service.recordHeavy(ViolationKind.statusBar);
      service.recordHeavy(ViolationKind.screenOff);
      service.issueTeacherToken('GURU-1234', const Duration(minutes: 5));

      expect(service.unlockWithToken('GURU-1234'), isTrue);
      expect(service.isLocked, isFalse);
      expect(service.count, 0);
    });

    test('token salah ditolak', () {
      final service = ViolationService();
      service.recordHeavy(ViolationKind.appSwitch);
      service.recordHeavy(ViolationKind.statusBar);
      service.recordHeavy(ViolationKind.screenOff);
      service.issueTeacherToken('GURU-1234', const Duration(minutes: 5));

      expect(service.unlockWithToken('SALAH'), isFalse);
      expect(service.isLocked, isTrue);
    });

    test('token kedaluwarsa ditolak', () {
      final service = ViolationService();
      service.recordHeavy(ViolationKind.appSwitch);
      service.recordHeavy(ViolationKind.statusBar);
      service.recordHeavy(ViolationKind.screenOff);
      service.issueTeacherToken('GURU-1234', const Duration(seconds: -1));

      expect(service.unlockWithToken('GURU-1234'), isFalse);
      expect(service.isLocked, isTrue);
    });

    test('token hanya sekali pakai', () {
      final service = ViolationService();
      service.recordHeavy(ViolationKind.appSwitch);
      service.recordHeavy(ViolationKind.statusBar);
      service.recordHeavy(ViolationKind.screenOff);
      service.issueTeacherToken('GURU-1234', const Duration(minutes: 5));

      expect(service.unlockWithToken('GURU-1234'), isTrue);
      expect(service.unlockWithToken('GURU-1234'), isFalse);
    });
  });

  group('ViolationService log senyap', () {
    test('kejadian ringan tidak menaikkan counter', () {
      final service = ViolationService();
      service.recordLight('Menekan tombol kembali 3 kali dalam 10 detik');

      expect(service.count, 0);
      expect(service.silentLog.length, 1);
      expect(service.isLocked, isFalse);
    });

    test('jawab di bawah 2 detik 3 kali beruntun dicatat senyap', () {
      final service = ViolationService();
      service.recordAnswerTiming(const Duration(seconds: 1));
      service.recordAnswerTiming(const Duration(seconds: 1));
      expect(service.silentLog, isEmpty);
      service.recordAnswerTiming(const Duration(seconds: 1));

      expect(service.count, 0);
      expect(service.silentLog.length, 1);
    });

    test('diam lebih dari 5 menit dicatat senyap', () {
      final service = ViolationService();
      service.recordIdle(const Duration(minutes: 6));

      expect(service.count, 0);
      expect(service.silentLog.length, 1);
    });

    test('spam tombol kembali dicatat senyap', () {
      final service = ViolationService();
      service.recordBackPress();
      service.recordBackPress();
      service.recordBackPress();

      expect(service.count, 0);
      expect(service.silentLog.length, 1);
    });

    test('telepon masuk hanya info, bukan pelanggaran', () {
      final service = ViolationService();
      service.recordPhoneCall();

      expect(service.count, 0);
      expect(service.isLocked, isFalse);
      expect(service.silentLog.length, 1);
    });
  });
}
