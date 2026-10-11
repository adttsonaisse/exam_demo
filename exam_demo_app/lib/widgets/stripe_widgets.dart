import 'package:flutter/material.dart';

import '../theme/stripe_theme.dart';

/// Tombol utama Stripe: ungu hanya untuk aksi interaktif, tinggi 48px.
class StripeButton extends StatelessWidget {
  const StripeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

/// Tombol sekunder berbingkai tipis.
class StripeGhostButton extends StatelessWidget {
  const StripeGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

/// Tombol bahaya untuk aksi mengunci atau mengumpulkan.
class StripeDangerButton extends StatelessWidget {
  const StripeDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: StripeColors.danger,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StripeRadius.control),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// Kartu Stripe: radius 6px, garis hairline, elevasi halus.
class StripeCard extends StatelessWidget {
  const StripeCard({super.key, required this.child, this.padding = 16});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: child,
      ),
    );
  }
}

/// Lencana status kecil: hijau untuk aman, merah untuk bahaya.
class StripeBadge extends StatelessWidget {
  const StripeBadge({super.key, required this.label, this.danger = false});

  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = danger ? StripeColors.dangerWash : StripeColors.successWash;
    final fg = danger ? StripeColors.dangerText : StripeColors.successText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(StripeRadius.control),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Bilah penghitung pelanggaran berat, misal Pelanggaran 1/3.
class ViolationCounter extends StatelessWidget {
  const ViolationCounter({super.key, required this.count, required this.max});

  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final aman = count == 0;
    return Semantics(
      label: 'Penghitung pelanggaran $count dari $max',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: aman ? StripeColors.successWash : StripeColors.dangerWash,
          borderRadius: BorderRadius.circular(StripeRadius.control),
          border: Border.all(
            color: aman ? StripeColors.success : StripeColors.danger,
          ),
        ),
        child: Text(
          'Pelanggaran $count/$max',
          style: TextStyle(
            color: aman ? StripeColors.successText : StripeColors.dangerText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Kotak pesan galat gaya Stripe tanpa garis kiri tebal.
class StripeAlert extends StatelessWidget {
  const StripeAlert({super.key, required this.message, this.success = false});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final bg = success ? StripeColors.successWash : StripeColors.dangerWash;
    final fg = success ? StripeColors.successText : StripeColors.dangerText;
    final icon = success ? Icons.check_circle : Icons.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(StripeRadius.control),
        border: Border.all(color: fg.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: fg, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris skeleton untuk status loading daftar, bukan spinner tengah.
class SkeletonRow extends StatefulWidget {
  const SkeletonRow({super.key});

  @override
  State<SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<SkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.5, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const StripeCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBar(width: 140),
            SizedBox(height: 8),
            _SkeletonBar(width: 220),
            SizedBox(height: 8),
            _SkeletonBar(width: 100),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      width: width,
      decoration: BoxDecoration(
        color: StripeColors.bone,
        borderRadius: BorderRadius.circular(StripeRadius.control),
      ),
    );
  }
}

/// Bilah aman kecil: ikon gembok dan teks mode aman.
class SecureBadge extends StatelessWidget {
  const SecureBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock, size: 14, color: StripeColors.body),
        SizedBox(width: 4),
        Text(
          'Mode aman',
          style: TextStyle(color: StripeColors.body, fontSize: 12),
        ),
      ],
    );
  }
}
