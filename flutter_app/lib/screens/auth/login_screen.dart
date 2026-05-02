// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  Future<void> _login() async {
  print("CLICK LOGIN");

  setState(() => _loading = true);

  try {
    final err = await context.read<AuthProvider>().login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    print("LOGIN RESULT: $err");

    if (!mounted) return;

    setState(() => _loading = false);

    if (err != null) {
      print("ERROR: $err");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err, style: GoogleFonts.kanit()),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      print("LOGIN SUCCESS");
    }

  } catch (e) {
    print("EXCEPTION: $e");
    setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.gold.withOpacity(0.12), Colors.transparent
                ]),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Center(
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 1.5),
                          color: AppColors.gold.withOpacity(0.08),
                        ),
                        child: const Icon(Icons.restaurant_menu, color: AppColors.gold, size: 40),
                      ),
                      const SizedBox(height: 20),
                      Text('Mobile Restaurant Table Reservation Application', style: GoogleFonts.playfairDisplay(
                        color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w700,
                      )),
                      const SizedBox(height: 6),
                      Text('ระบบจองโต๊ะอาหาร', style: GoogleFonts.kanit(
                        color: AppColors.textSecondary, fontSize: 14,
                      )),
                    ]),
                  ),
                  const SizedBox(height: 48),
                  const GoldDivider(),
                  const SizedBox(height: 32),
                  Text('เข้าสู่ระบบ', style: GoogleFonts.kanit(
                    color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700,
                  )),
                  const SizedBox(height: 24),
                  // Email
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.kanit(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'อีเมล',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.textHint),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    style: GoogleFonts.kanit(color: AppColors.textPrimary),
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textHint,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GoldButton(
                    text: 'เข้าสู่ระบบ',
                    loading: _loading,
                    onTap: _login,
                    icon: Icons.login_rounded,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: RichText(text: TextSpan(
                        style: GoogleFonts.kanit(color: AppColors.textSecondary, fontSize: 14),
                        children: [
                          const TextSpan(text: 'ยังไม่มีบัญชี? '),
                          TextSpan(text: 'สมัครสมาชิก',
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
                        ],
                      )),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
