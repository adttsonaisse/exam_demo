import 'package:flutter/material.dart';

import '../main.dart';
import '../theme/stripe_theme.dart';
import '../widgets/stripe_widgets.dart';
import 'exam_list_screen.dart';

/// Layar masuk: NISN 10 digit dan kata sandi.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nisnController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _tutup = true;

  @override
  void dispose() {
    _nisnController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validasiNisn(String? value) {
    if (value == null || value.isEmpty) {
      return 'Isi NISN dulu. NISN ada di kartu pelajar kamu.';
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
      return 'NISN harus 10 angka, tanpa huruf atau spasi.';
    }
    return null;
  }

  String? _validasiPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Isi kata sandi dulu.';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter.';
    }
    return null;
  }

  Future<void> _masuk() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final store = AppScope.of(context).store;
    final ok = await store.login(
      _nisnController.text.trim(),
      _passwordController.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ExamListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    return Scaffold(
      backgroundColor: StripeColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.school,
                      size: 40,
                      color: StripeColors.primary,
                      semanticLabel: 'Logo ujian sekolah',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Masuk Ujian',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masuk dengan NISN dan kata sandi dari wali kelas untuk melihat jadwal ujian kamu.',
                      style: TextStyle(
                        color: StripeColors.body,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ListenableBuilder(
                      listenable: store,
                      builder: (context, _) {
                        if (store.error != null) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: StripeAlert(message: store.error!),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    TextFormField(
                      controller: _nisnController,
                      decoration: const InputDecoration(
                        labelText: 'NISN',
                        hintText: 'Contoh: 1234567890',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      validator: _validasiNisn,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Kata sandi',
                        hintText: 'Minimal 6 karakter',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _tutup ? Icons.visibility : Icons.visibility_off,
                          ),
                          tooltip:
                              _tutup ? 'Tampilkan sandi' : 'Sembunyikan sandi',
                          onPressed: () => setState(() => _tutup = !_tutup),
                        ),
                      ),
                      obscureText: _tutup,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _masuk(),
                      validator: _validasiPassword,
                    ),
                    const SizedBox(height: 20),
                    ListenableBuilder(
                      listenable: store,
                      builder: (context, _) {
                        return StripeButton(
                          label: 'Masuk',
                          isLoading: store.isLoading,
                          onPressed: _masuk,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Lupa kata sandi? Minta reset ke wali kelas. Jangan bagikan akun ke teman.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: StripeColors.body,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
