import 'package:exam_demo_app/main.dart';
import 'package:exam_demo_app/models/exam_models.dart';
import 'package:exam_demo_app/screens/locked_screen.dart';
import 'package:exam_demo_app/services/exam_store.dart';
import 'package:exam_demo_app/services/violation_service.dart';
import 'package:exam_demo_app/theme/stripe_theme.dart';
import 'package:exam_demo_app/widgets/stripe_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _exam = ExamInfo(
  id: 1,
  mapel: 'Matematika',
  durasiMenit: 90,
  status: ExamStatus.belumMulai,
  jumlahSoal: 5,
);

Widget _harness({
  required ExamStore store,
  required ViolationService violations,
  required Widget home,
}) {
  return AppScope(
    store: store,
    violations: violations,
    child: MaterialApp(theme: stripeTheme(), home: home),
  );
}

class _CounterProbe extends StatelessWidget {
  const _CounterProbe();

  @override
  Widget build(BuildContext context) {
    final violations = AppScope.of(context).violations;
    return Scaffold(
      body: Center(
        child: ListenableBuilder(
          listenable: violations,
          builder: (context, _) => ViolationCounter(
            count: violations.count,
            max: maxViolations,
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets(
    'counter 0-1-2 tampil, pelanggaran ke-3 mengunci, token membuka',
    (tester) async {
      final store = ExamStore();
      final violations = ViolationService();

      await tester.pumpWidget(
        _harness(
          store: store,
          violations: violations,
          home: const _CounterProbe(),
        ),
      );
      // startExam memakai Future.delayed: majukan jam palsu agar selesai.
      final mulai = store.startExam(_exam);
      await tester.pump(const Duration(milliseconds: 600));
      await mulai;
      await tester.pump();
      expect(find.text('Pelanggaran 0/3'), findsOneWidget);

      violations.recordHeavy(ViolationKind.appSwitch);
      await tester.pump();
      expect(find.text('Pelanggaran 1/3'), findsOneWidget);
      expect(violations.isLocked, isFalse);

      violations.recordHeavy(ViolationKind.statusBar);
      await tester.pump();
      expect(find.text('Pelanggaran 2/3'), findsOneWidget);
      expect(violations.isLocked, isFalse);

      violations.recordHeavy(ViolationKind.screenOff);
      await tester.pump();
      expect(violations.isLocked, isTrue);

      final token = store.issueTeacherToken();
      violations.issueTeacherToken(token, const Duration(minutes: 5));

      await tester.pumpWidget(
        _harness(
          store: store,
          violations: violations,
          home: const LockedScreen(
            exam: _exam,
            alasan: 'Mematikan atau mengunci layar',
          ),
        ),
      );
      expect(find.text('Ujian Terkunci'), findsOneWidget);
      expect(find.text('Pelanggaran 3/3'), findsNothing);

      await tester.ensureVisible(find.byKey(const Key('tokenField')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('tokenField')), token);
      await tester.tap(find.text('Buka dengan Token Guru'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(violations.isLocked, isFalse);
      expect(find.text('Soal 1 dari 5'), findsOneWidget);
    },
  );

  testWidgets('token salah menampilkan galat dan tetap terkunci', (
    tester,
  ) async {
    final store = ExamStore();
    final violations = ViolationService();

    await tester.pumpWidget(
      _harness(
        store: store,
        violations: violations,
        home: const LockedScreen(exam: _exam, alasan: 'Uji kunci'),
      ),
    );
    final mulai = store.startExam(_exam);
    await tester.pump(const Duration(milliseconds: 600));
    await mulai;
    await tester.pump();

    violations.recordHeavy(ViolationKind.appSwitch);
    violations.recordHeavy(ViolationKind.statusBar);
    violations.recordHeavy(ViolationKind.screenOff);
    violations.issueTeacherToken('GURU-9999', const Duration(minutes: 5));

    await tester.pumpWidget(
      _harness(
        store: store,
        violations: violations,
        home: const LockedScreen(exam: _exam, alasan: 'Uji kunci'),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('tokenField')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('tokenField')), 'SALAH');
    await tester.tap(find.text('Buka dengan Token Guru'));
    await tester.pump();

    expect(violations.isLocked, isTrue);
    expect(find.textContaining('Token salah'), findsOneWidget);
  });
}
