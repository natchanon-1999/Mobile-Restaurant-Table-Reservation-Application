import 'package:flutter/material.dart';
import '../models/models.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? user;
  bool isLoggedIn = false;

  // ✅ เช็คว่าเป็น admin
  bool get isAdmin => user?.role == 'admin';

  // ─── INIT ─────────────────────────
  Future<void> init() async {
    try {
      await ApiService.loadToken();
      final profile = await ApiService.getProfile();

      if (profile != null) {
        user = profile;
        isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      print("INIT ERROR: $e");
    }
  }

  // ─── LOGIN ────────────────────────
  Future<String?> login(String email, String password) async {
    try {
      print("🔥 CALL API LOGIN");

      final res = await ApiService.login(email, password);

      print("🔥 RESPONSE: $res");

      if (res['success'] == true) {
        await ApiService.saveToken(res['token']);

        user = UserModel.fromJson(res['user']);
        isLoggedIn = true;

        notifyListeners();
        return null;
      } else {
        return res['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ';
      }

    } catch (e) {
      print("🔥 LOGIN ERROR: $e");
      return 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้';
    }
  }

  // ─── REGISTER ─────────────────────
  Future<String?> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    try {
      print("🔥 CALL API REGISTER");

      final res = await ApiService.register(name, email, phone, password);

      print("🔥 RESPONSE: $res");

      if (res['success'] == true) {
        await ApiService.saveToken(res['token']);

        user = UserModel.fromJson(res['user']);
        isLoggedIn = true;

        notifyListeners();
        return null;
      } else {
        return res['message'] ?? 'สมัครสมาชิกไม่สำเร็จ';
      }

    } catch (e) {
      print("🔥 REGISTER ERROR: $e");
      return 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้';
    }
  }

  // ─── UPDATE PROFILE ──────────────────
  Future<void> updateProfile(String name, String phone) async {
    if (user == null) return;
    user = UserModel(
      id: user!.id,
      name: name.isNotEmpty ? name : user!.name,
      email: user!.email,
      phone: phone.isNotEmpty ? phone : user!.phone,
      role: user!.role,
      avatarUrl: user!.avatarUrl,
    );
    notifyListeners();
  }

  // ─── UPDATE AVATAR ───────────────────
  Future<void> updateAvatar(String url) async {
    if (user == null) return;
    user = UserModel(
      id: user!.id,
      name: user!.name,
      email: user!.email,
      phone: user!.phone,
      role: user!.role,
      avatarUrl: url.isEmpty ? null : url,
    );
    notifyListeners();
    // optional: sync กับ backend ถ้ามี API
    // await ApiService.updateProfile({'avatar_url': url});
  }

  // ─── LOGOUT ──────────────────────
  Future<void> logout() async {
    await ApiService.clearToken();
    user = null;
    isLoggedIn = false;
    notifyListeners();
  }
}

