// lib/screens/admin/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final raw = await ApiService.getDashboardStats();
      Map<String, dynamic>? parsed;

      if (raw is Map<String, dynamic>) {
        parsed = raw['success'] == true ? raw : null;
      } else if (raw is List && raw.isNotEmpty) {
        final first = raw[0];
        if (first is Map<String, dynamic>) parsed = first;
      }

      if (parsed != null) {
        final ut = parsed['upcoming_today'];
        parsed['upcoming_today'] = (ut is List) ? ut : [];
        final sb = parsed['status_breakdown'];
        parsed['status_breakdown'] = (sb is Map)
            ? Map<String, dynamic>.from(sb)
            : <String, dynamic>{};
      }

      if (mounted) setState(() { _stats = parsed; _loading = false; });
    } catch (e) {
      print('LOAD STATS ERROR: ' + e.toString());
      if (mounted) setState(() { _stats = null; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppColors.bg,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A1200), AppColors.bg],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -40, right: -40,
                      child: Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            AppColors.gold.withOpacity(0.2),
                            Colors.transparent,
                          ]),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('สวัสดี, ${user?.name.split(' ').first ?? 'Admin'}',
                              style: GoogleFonts.kanit(
                                  color: AppColors.textSecondary, fontSize: 13)),
                          Text('แดชบอร์ดผู้ดูแลระบบ',
                              style: GoogleFonts.playfairDisplay(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              title: Text('Admin Dashboard',
                  style: GoogleFonts.playfairDisplay(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _loading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: AppColors.gold),
                        ))
                    : _stats == null
                        ? const Center(
                            child: Text('ไม่สามารถโหลดข้อมูลได้',
                                style: TextStyle(color: AppColors.textSecondary)))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stat Cards
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.5,
                                children: [
                                  _StatCard(
                                    label: 'โต๊ะทั้งหมด',
                                    value: '${_stats!['total_tables'] ?? 0}',
                                    icon: Icons.table_restaurant_outlined,
                                    color: AppColors.gold,
                                  ),
                                  _StatCard(
                                    label: 'ลูกค้าทั้งหมด',
                                    value: '${_stats!['total_customers'] ?? 0}',
                                    icon: Icons.people_outline,
                                    color: AppColors.info,
                                  ),
                                  _StatCard(
                                    label: 'จองวันนี้',
                                    value: '${_stats!['today_reservations'] ?? 0}',
                                    icon: Icons.today_outlined,
                                    color: AppColors.success,
                                  ),
                                  _StatCard(
                                    label: 'จองเดือนนี้',
                                    value: '${_stats!['month_reservations'] ?? 0}',
                                    icon: Icons.calendar_month_outlined,
                                    color: AppColors.warning,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),

                              // Status breakdown
                              SectionTitle('สถานะการจองวันนี้'),
                              const SizedBox(height: 14),
                              _StatusBreakdown(
                                  breakdown: Map<String, dynamic>.from(
                                      _stats!['status_breakdown'] ?? {})),
                              const SizedBox(height: 28),

                              // Peak hours
                              SectionTitle('ช่วงเวลายอดนิยม'),
                              const SizedBox(height: 14),
                              _PeakHoursBreakdown(
                                reservations: List<Map<String, dynamic>>.from(
                                  (_stats!['upcoming_today'] as List? ?? [])
                                      .map((e) => Map<String, dynamic>.from(e as Map))
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Today's upcoming reservations
                              SectionTitle('การจองวันนี้'),
                              const SizedBox(height: 14),
                              if ((_stats!['upcoming_today'] as List?)
                                      ?.isEmpty ??
                                  true)
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Center(
                                    child: Text('ยังไม่มีการจองวันนี้',
                                        style: GoogleFonts.kanit(
                                            color: AppColors.textSecondary)),
                                  ),
                                )
                              else
                                ...(_stats!['upcoming_today'] as List)
                                    .take(5)
                                    .map((r) => _TodayCard(reservation: r)),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: GoogleFonts.kanit(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: GoogleFonts.kanit(
                    color: AppColors.textSecondary, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}

// ─── Status Breakdown ─────────────────────────────
class _StatusBreakdown extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  const _StatusBreakdown({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final statuses = {
      'confirmed': ('ยืนยัน', AppColors.success),
      // 'pending':   ('รอยืนยัน', AppColors.warning),
      // 'completed': ('เสร็จสิ้น', AppColors.info),
      'cancelled': ('ยกเลิก', AppColors.error),
      'no_show':   ('ไม่มา', AppColors.textHint),
    };

    final total = breakdown.values.fold<int>(
        0, (sum, v) => sum + (int.tryParse(v.toString()) ?? 0));
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(child: Text('ไม่มีข้อมูล',
            style: GoogleFonts.kanit(color: AppColors.textSecondary))),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: statuses.entries.map((e) {
          final count = int.tryParse(
                  breakdown[e.key]?.toString() ?? '0') ??
              0;
          final pct = total > 0 ? count / total : 0.0;
          final color = e.value.$2;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                  width: 70,
                  child: Text(e.value.$1,
                      style: GoogleFonts.kanit(
                          color: AppColors.textSecondary, fontSize: 12))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.surfaceAlt,
                    color: color,
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 30,
                child: Text('$count',
                    style: GoogleFonts.kanit(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.right),
              ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Peak Hours Breakdown ─────────────────────────
class _PeakHoursBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> reservations;
  const _PeakHoursBreakdown({required this.reservations});

  static const _slots = [
    ('11:30 - 13:30', '11:30', '13:30'),
    ('14:00 - 16:00', '14:00', '16:00'),
    ('19:00 - 21:00', '19:00', '21:00'),
    ('21:00 - 23:00', '21:00', '23:00'),
  ];

  int _toMinutes(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int _countInSlot(String start, String end) {
    final s = _toMinutes(start);
    final e = _toMinutes(end);
    return reservations.where((r) {
      final raw = (r['start_time'] as String? ?? '').substring(0, 5);
      if (raw.isEmpty) return false;
      final m = _toMinutes(raw);
      return m >= s && m < e;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _slots.map((s) => _countInSlot(s.$2, s.$3)).toList();
    final maxCount = counts.fold(0, (a, b) => a > b ? a : b);
    final total = counts.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(_slots.length, (i) {
          final label = _slots[i].$1;
          final count = counts[i];
          final pct = total > 0 ? count / total : 0.0;
          final isTop = maxCount > 0 && count == maxCount;
          final barColor = isTop ? AppColors.gold : AppColors.info;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  if (isTop)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.local_fire_department,
                          color: AppColors.gold, size: 14),
                    ),
                  Text(label,
                      style: GoogleFonts.kanit(
                          color: isTop
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isTop
                              ? FontWeight.w700
                              : FontWeight.normal)),
                  const Spacer(),
                  Text(
                    count > 0
                        ? '${(pct * 100).round()}%  ($count การจอง)'
                        : 'ว่าง',
                    style: GoogleFonts.kanit(
                        color: isTop ? AppColors.gold : AppColors.textHint,
                        fontSize: 12,
                        fontWeight: isTop
                            ? FontWeight.w700
                            : FontWeight.normal),
                  ),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.surfaceAlt,
                    color: barColor,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Today's Reservation Card ─────────────────────
class _TodayCard extends StatelessWidget {
  final Map<String, dynamic> reservation;
  const _TodayCard({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            (r['start_time'] as String?)?.substring(0, 5) ?? '--:--',
            style: GoogleFonts.sourceCodePro(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r['user_name'] ?? '',
                style: GoogleFonts.kanit(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            Text(
                'โต๊ะ ${r['table_number']} • ${r['guest_count']} คน',
                style: GoogleFonts.kanit(
                    color: AppColors.textSecondary, fontSize: 12)),
          ]),
        ),
        StatusBadge(r['status'] ?? 'pending'),
      ]),
    );
  }
}
