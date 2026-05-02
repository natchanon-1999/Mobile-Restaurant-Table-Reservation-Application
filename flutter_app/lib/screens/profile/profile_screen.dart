// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../home/home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gold.withOpacity(0.08),
                    AppColors.bg,
                  ],
                ),
              ),
              child: Column(children: [
                // ── Avatar กดเพื่อเปลี่ยนรูป ──
                GestureDetector(
                  onTap: () => _showChangeAvatarDialog(context, auth),
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                        ),
                        child: ClipOval(
                          child: (user?.avatarUrl != null &&
                                  user!.avatarUrl!.isNotEmpty)
                              ? Image.network(
                                  user.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _defaultAvatar(user.name),
                                )
                              : _defaultAvatar(user?.name ?? '?'),
                        ),
                      ),
                      // ไอคอน camera มุมล่างขวา
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.bg, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: AppColors.bg, size: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? '',
                  style: GoogleFonts.kanit(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: GoogleFonts.kanit(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                if (user?.isAdmin == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.gold, AppColors.goldDark],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.admin_panel_settings,
                          color: AppColors.bg, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'ผู้ดูแลระบบ',
                        style: GoogleFonts.kanit(
                            color: AppColors.bg,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
              ]),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GoldDivider(),
                  const SizedBox(height: 24),

                  _InfoCard(user: user),
                  const SizedBox(height: 20),

                  Text(
                    'การตั้งค่า',
                    style: GoogleFonts.kanit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),

                  _MenuItem(
                    icon: Icons.edit_outlined,
                    label: 'แก้ไขโปรไฟล์',
                    onTap: () => _showEditProfile(
                        context, auth, user?.name ?? '', user?.phone ?? ''),
                  ),
                  _MenuItem(
                    icon: Icons.add_a_photo_outlined,
                    label: 'เปลี่ยนรูปโปรไฟล์',
                    onTap: () => _showChangeAvatarDialog(context, auth),
                  ),
                  _MenuItem(
                    icon: Icons.history_outlined,
                    label: 'ประวัติการจอง',
                    onTap: () => homeScreenKey.currentState?.switchTab(2),
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'การแจ้งเตือน',
                    onTap: () => _showComingSoon(context, 'การแจ้งเตือน'),
                  ),
                  _MenuItem(
                    icon: Icons.help_outline,
                    label: 'ช่วยเหลือ',
                    onTap: () => _showHelp(context),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'บัญชี',
                    style: GoogleFonts.kanit(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),

                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'ออกจากระบบ',
                    color: AppColors.error,
                    onTap: () => _confirmLogout(context, auth),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Default Avatar (ตัวอักษร) ──
  Widget _defaultAvatar(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold, AppColors.goldDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.bg,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Dialog เปลี่ยน Avatar URL ──
  void _showChangeAvatarDialog(BuildContext context, AuthProvider auth) {
    final urlCtrl =
        TextEditingController(text: auth.user?.avatarUrl ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'เปลี่ยนรูปโปรไฟล์',
              style: GoogleFonts.kanit(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Preview
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: ClipOval(
                child: urlCtrl.text.trim().isNotEmpty
                    ? Image.network(
                        urlCtrl.text.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _defaultAvatar(auth.user?.name ?? '?'),
                      )
                    : _defaultAvatar(auth.user?.name ?? '?'),
              ),
            ),
            const SizedBox(height: 16),

            // URL input
            TextField(
              controller: urlCtrl,
              style: GoogleFonts.kanit(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'URL รูปภาพ',
                hintText: 'https://...',
                prefixIcon:
                    Icon(Icons.image_outlined, color: AppColors.textHint),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'วาง URL รูปภาพจากอินเทอร์เน็ต',
              style: GoogleFonts.kanit(
                  color: AppColors.textHint, fontSize: 11),
            ),
            const SizedBox(height: 20),

            Row(children: [
              // ปุ่มลบรูป
              if ((auth.user?.avatarUrl ?? '').isNotEmpty)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await auth.updateAvatar('');
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                    ),
                    child: Text('ลบรูป', style: GoogleFonts.kanit()),
                  ),
                ),
              if ((auth.user?.avatarUrl ?? '').isNotEmpty)
                const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await auth.updateAvatar(urlCtrl.text.trim());
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('อัปเดตรูปโปรไฟล์สำเร็จ',
                            style: GoogleFonts.kanit()),
                        backgroundColor: AppColors.success,
                      ));
                    }
                  },
                  child: Text('บันทึก', style: GoogleFonts.kanit()),
                ),
              ),
            ]),
          ]),
        );
      }),
    );
  }

  void _showEditProfile(BuildContext context, AuthProvider auth,
      String name, String phone) {
    final nameCtrl = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        String? nameError;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'แก้ไขโปรไฟล์',
              style: GoogleFonts.kanit(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            StatefulBuilder(builder: (ctx2, setErr) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.kanit(color: AppColors.textPrimary),
                    onChanged: (_) {
                      if (nameError != null) setErr(() => nameError = null);
                    },
                    decoration: InputDecoration(
                      labelText: 'ชื่อ-นามสกุล',
                      hintText: 'เช่น สมชาย ใจดี',
                      prefixIcon: const Icon(Icons.person_outline,
                          color: AppColors.textHint),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: nameError != null
                              ? AppColors.error
                              : AppColors.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: nameError != null
                              ? AppColors.error
                              : AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                  if (nameError != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        nameError!,
                        style: GoogleFonts.kanit(
                            color: AppColors.error, fontSize: 12),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.kanit(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'เบอร์โทรศัพท์',
                      prefixIcon: Icon(Icons.phone_outlined,
                          color: AppColors.textHint),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GoldButton(
                    text: 'บันทึก',
                    onTap: () async {
                      final nameTrimmed = nameCtrl.text.trim();
                      final parts = nameTrimmed
                          .split(' ')
                          .where((p) => p.isNotEmpty)
                          .toList();
                      if (parts.length < 2) {
                        setErr(() => nameError = 'กรุณากรอกชื่อและนามสกุล (เว้นช่องระหว่างกลาง)');
                        return;
                      }
                      await auth.updateProfile(
                          nameTrimmed, phoneCtrl.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('อัปเดตข้อมูลสำเร็จ',
                              style: GoogleFonts.kanit()),
                          backgroundColor: AppColors.success,
                        ));
                      }
                    },
                  ),
                ],
              );
            }),
          ]),
        );
      }),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — เร็วๆ นี้', style: GoogleFonts.kanit()),
      backgroundColor: AppColors.surfaceAlt,
    ));
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ช่วยเหลือ',
            style: GoogleFonts.kanit(color: AppColors.textPrimary)),
        content: Text(
          'หากมีปัญหาการใช้งาน กรุณาติดต่อ\n📞 02-xxx-xxxx\n✉️ support@midnightbistro.com',
          style: GoogleFonts.kanit(
              color: AppColors.textSecondary, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ปิด',
                style: GoogleFonts.kanit(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ออกจากระบบ',
            style: GoogleFonts.kanit(color: AppColors.textPrimary)),
        content: Text('ต้องการออกจากระบบ?',
            style: GoogleFonts.kanit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก',
                style:
                    GoogleFonts.kanit(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              auth.logout();
              Navigator.pop(context);
            },
            child: Text('ออกจากระบบ',
                style: GoogleFonts.kanit(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final dynamic user;
  const _InfoCard({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        _row(Icons.person_outline, 'ชื่อ', user?.name ?? '-'),
        const Divider(color: AppColors.border, height: 20),
        _row(Icons.email_outlined, 'อีเมล', user?.email ?? '-'),
        const Divider(color: AppColors.border, height: 20),
        _row(Icons.phone_outlined, 'โทรศัพท์', user?.phone ?? '-'),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, color: AppColors.gold, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.kanit(
                  color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.kanit(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      );
}

// ─── Menu Item ────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(
            icon,
            color: color == AppColors.textPrimary ? AppColors.gold : color,
            size: 20,
          ),
          const SizedBox(width: 14),
          Text(label,
              style: GoogleFonts.kanit(color: color, fontSize: 15)),
          const Spacer(),
          Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
        ]),
      ),
    );
  }
}
