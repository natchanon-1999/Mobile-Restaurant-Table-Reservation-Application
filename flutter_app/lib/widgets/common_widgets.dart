// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─── Gold Divider ─────────────────────────────────
class GoldDivider extends StatelessWidget {
  const GoldDivider({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [
        Colors.transparent,
        AppColors.goldDark,
        AppColors.gold,
        AppColors.goldDark,
        Colors.transparent,
      ]),
    ),
  );
}

// ─── Status Badge ─────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  static const _colors = {
    'confirmed': AppColors.success,
    'pending':   AppColors.warning,
    'cancelled': AppColors.error,
    'completed': AppColors.info,
    'no_show':   AppColors.textHint,
  };

  static const _labels = {
    'confirmed': 'ยืนยันแล้ว',
    'pending':   'รอยืนยัน',
    'cancelled': 'ยกเลิก',
    'completed': 'เสร็จสิ้น',
    'no_show':   'ไม่มา',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? AppColors.textHint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        _labels[status] ?? status,
        style: GoogleFonts.kanit(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Zone Badge ───────────────────────────────────
class ZoneBadge extends StatelessWidget {
  final String zone;
  const ZoneBadge(this.zone, {super.key});

  static const _icons = {
    'indoor':   Icons.weekend_outlined,
    'outdoor':  Icons.park_outlined,
    'vip':      Icons.star_outline,
    'rooftop':  Icons.roofing_outlined,
  };

  static const _colors = {
    'indoor':  AppColors.indoor,
    'outdoor': AppColors.outdoor,
    'vip':     AppColors.vip,
    'rooftop': AppColors.rooftop,
  };

  static const _labels = {
    'indoor':  'Indoor',
    'outdoor': 'Outdoor',
    'vip':     'VIP',
    'rooftop': 'Rooftop',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[zone] ?? AppColors.textHint;
    final icon  = _icons[zone]  ?? Icons.table_restaurant_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(_labels[zone] ?? zone, style: GoogleFonts.kanit(
          color: color, fontSize: 11, fontWeight: FontWeight.w500,
        )),
      ]),
    );
  }
}

// ─── Gold Button ──────────────────────────────────
class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;

  const GoldButton({
    super.key,
    required this.text,
    this.onTap,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: loading ? null : onTap,
    child: loading
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(text),
          ]),
  );
}

// ─── Section Title ────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.kanit(
          color: AppColors.textPrimary,
          fontSize: 18, fontWeight: FontWeight.w700,
        )),
        if (subtitle != null) Text(subtitle!, style: GoogleFonts.kanit(
          color: AppColors.textSecondary, fontSize: 12,
        )),
      ]),
      const Spacer(),
      if (trailing != null) trailing!,
    ],
  );
}

// ─── Empty State ──────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: AppColors.textHint, size: 64),
      const SizedBox(height: 16),
      Text(title, style: GoogleFonts.kanit(
        color: AppColors.textSecondary, fontSize: 18, fontWeight: FontWeight.w600,
      )),
      const SizedBox(height: 8),
      Text(subtitle, style: GoogleFonts.kanit(color: AppColors.textHint, fontSize: 14),
        textAlign: TextAlign.center),
    ]),
  );
}

// ─── Reservation Card ─────────────────────────────
class ReservationCard extends StatelessWidget {
  final dynamic reservation;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const ReservationCard({super.key, required this.reservation, this.onTap, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.table_restaurant_outlined, color: AppColors.gold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('โต๊ะ ${reservation.tableNumber}',
                    style: GoogleFonts.kanit(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  Text(reservation.reservationCode,
                    style: GoogleFonts.kanit(color: AppColors.textHint, fontSize: 12)),
                ])),
                StatusBadge(reservation.status),
              ]),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _infoRow(Icons.calendar_today_outlined, reservation.displayDate),
                const SizedBox(height: 8),
                _infoRow(Icons.access_time_outlined, reservation.displayTime),
                const SizedBox(height: 8),
                _infoRow(Icons.people_outline, '${reservation.guestCount} คน'),
                if (reservation.occasion.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.celebration_outlined, _occasionLabel(reservation.occasion)),
                ],
                if (onCancel != null && reservation.status == 'confirmed') ...[
                  const SizedBox(height: 12),
                  const GoldDivider(),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 16),
                    label: Text('ยกเลิกการจอง',
                      style: GoogleFonts.kanit(color: AppColors.error, fontSize: 13)),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(children: [
    Icon(icon, color: AppColors.gold, size: 16),
    const SizedBox(width: 8),
    Text(text, style: GoogleFonts.kanit(color: AppColors.textSecondary, fontSize: 13)),
  ]);

  String _occasionLabel(String o) {
    const map = {
      'birthday': '🎂 วันเกิด',
      'anniversary': '💍 ครบรอบ',
      'business': '💼 ธุรกิจ',
      'date': '❤️ เดต',
      'family': '👨‍👩‍👧 ครอบครัว',
    };
    return map[o] ?? o;
  }
}
