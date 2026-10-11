import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/exam_store.dart';
import '../services/violation_service.dart';
import '../theme/stripe_theme.dart';

void main() {
  runApp(const ExamApp());
}

/// Akar aplikasi: memegang [ExamStore] dan [ViolationService]
/// lalu menurunkannya lewat [AppScope] tanpa paket tambahan.
class ExamApp extends StatefulWidget {
  const ExamApp({super.key});

  @override
  State<ExamApp> createState() => _ExamAppState();
}

class _ExamAppState extends State<ExamApp> {
  late final ExamStore store;
  late final ViolationService violations;

  @override
  void initState() {
    super.initState();
    store = ExamStore();
    violations = ViolationService();
  }

  @override
  void dispose() {
    store.dispose();
    violations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      violations: violations,
      child: MaterialApp(
        title: 'Ujian Sekolah',
        theme: stripeTheme(),
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
      ),
    );
  }
}

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.store,
    required this.violations,
    required super.child,
  });

  final ExamStore store;
  final ViolationService violations;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan di atas widget ini');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      store != oldWidget.store || violations != oldWidget.violations;
}
