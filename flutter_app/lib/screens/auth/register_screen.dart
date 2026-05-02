// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _register() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กรุณากรอกข้อมูลให้ครบ'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().register(
      _nameCtrl.text.trim(), _emailCtrl.text.trim(),
      _phoneCtrl.text.trim(), _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err, style: GoogleFonts.kanit()),
        backgroundColor: AppColors.error,
      ));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('สร้างบัญชีใหม่', style: GoogleFonts.kanit(
              color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 8),
            Text('กรอกข้อมูลเพื่อเริ่มใช้งาน', style: GoogleFonts.kanit(color: AppColors.textSecondary)),
            const SizedBox(height: 32),
            _field(_nameCtrl, 'ชื่อ-นามสกุล', Icons.person_outline),
            const SizedBox(height: 16),
            _field(_emailCtrl, 'อีเมล', Icons.email_outlined, type: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _field(_phoneCtrl, 'เบอร์โทรศัพท์', Icons.phone_outlined, type: TextInputType.phone),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              style: GoogleFonts.kanit(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'รหัสผ่าน',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: AppColors.textHint),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GoldButton(text: 'สมัครสมาชิก', loading: _loading, onTap: _register),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.kanit(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textHint),
      ),
    );
  }
}
