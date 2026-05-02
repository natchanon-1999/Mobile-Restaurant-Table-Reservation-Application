
<?php
// =====================================================
// auth.php — FINAL VERSION (Flutter Ready + Stable)
// =====================================================

// ─────────────────────────────────────────────────────
// ✅ CORS (สำคัญมาก)
// ─────────────────────────────────────────────────────
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ─────────────────────────────────────────────────────
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$path   = $_GET['action'] ?? '';

// ─────────────────────────────────────────────────────
// ROUTER
// ─────────────────────────────────────────────────────
switch ($method . ':' . $path) {
    case 'POST:register':
        handleRegister();
        break;

    case 'POST:login':
        handleLogin();
        break;

    case 'GET:profile':
        handleProfile();
        break;

    case 'PUT:profile':
        handleUpdateProfile();
        break;

    default:
        jsonResponse([
            'success' => false,
            'message' => 'Route not found',
            'debug' => [
                'method' => $method,
                'action' => $path
            ]
        ], 404);
}

// ─────────────────────────────────────────────────────
// REGISTER
// ─────────────────────────────────────────────────────
function handleRegister(): void {
    $db   = getDB();
    $body = getRequestBody();

    $name  = trim($body['name'] ?? '');
    $email = trim($body['email'] ?? '');
    $phone = trim($body['phone'] ?? '');
    $pass  = $body['password'] ?? '';

    if (!$name || !$email || !$phone || !$pass) {
        jsonResponse(['success' => false, 'message' => 'กรุณากรอกข้อมูลให้ครบ'], 400);
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        jsonResponse(['success' => false, 'message' => 'อีเมลไม่ถูกต้อง'], 400);
    }

    $stmt = $db->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->execute([$email]);
    if ($stmt->fetch()) {
        jsonResponse(['success' => false, 'message' => 'อีเมลถูกใช้แล้ว'], 409);
    }

    $hash = password_hash($pass, PASSWORD_BCRYPT);

    $stmt = $db->prepare("INSERT INTO users (name, email, phone, password, role) VALUES (?, ?, ?, ?, 'customer')");
    $stmt->execute([$name, $email, $phone, $hash]);

    $userId = $db->lastInsertId();

    $token = generateJWT([
        'id' => $userId,
        'email' => $email,
        'role' => 'customer'
    ]);

    jsonResponse([
        'success' => true,
        'message' => 'สมัครสมาชิกสำเร็จ',
        'token'   => $token,
        'user'    => [
            'id' => $userId,
            'name' => $name,
            'email' => $email,
            'phone' => $phone,
            'role' => 'customer'
        ]
    ], 201);
}

// ─────────────────────────────────────────────────────
// LOGIN
// ─────────────────────────────────────────────────────
function handleLogin(): void {
    $db   = getDB();
    $body = getRequestBody();

    $email = trim($body['email'] ?? '');
    $pass  = $body['password'] ?? '';

    if (!$email || !$pass) {
        jsonResponse(['success' => false, 'message' => 'กรอก email และ password'], 400);
    }

    $stmt = $db->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        jsonResponse(['success' => false, 'message' => 'ไม่พบผู้ใช้'], 404);
    }

    // ✅ รองรับทั้ง hash และ plain text (กันพลาดช่วง dev)
    // ✅ แก้เป็น
    $isValid = $pass === $user['password'] 
        || password_verify($pass, $user['password']);

    if (!$isValid) {
        jsonResponse(['success' => false, 'message' => 'รหัสผ่านไม่ถูกต้อง'], 401);
    }

    $token = generateJWT([
        'id' => $user['id'],
        'email' => $user['email'],
        'role' => $user['role']
    ]);

    unset($user['password']);

    jsonResponse([
        'success' => true,
        'message' => 'เข้าสู่ระบบสำเร็จ',
        'token'   => $token,
        'user'    => $user
    ]);
}

// ─────────────────────────────────────────────────────
// PROFILE
// ─────────────────────────────────────────────────────
function handleProfile(): void {
    $db   = getDB();
    $auth = requireAuth();

    $stmt = $db->prepare("SELECT id, name, email, phone, role FROM users WHERE id = ?");
    $stmt->execute([$auth['id']]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        jsonResponse(['success' => false, 'message' => 'ไม่พบผู้ใช้'], 404);
    }

    jsonResponse(['success' => true, 'user' => $user]);
}

// ─────────────────────────────────────────────────────
// UPDATE PROFILE
// ─────────────────────────────────────────────────────
function handleUpdateProfile(): void {
    $db   = getDB();
    $auth = requireAuth();
    $body = getRequestBody();

    $name  = trim($body['name'] ?? '');
    $phone = trim($body['phone'] ?? '');

    if (!$name || !$phone) {
        jsonResponse(['success' => false, 'message' => 'กรอกข้อมูลไม่ครบ'], 400);
    }

    $stmt = $db->prepare("UPDATE users SET name = ?, phone = ? WHERE id = ?");
    $stmt->execute([$name, $phone, $auth['id']]);

    jsonResponse(['success' => true, 'message' => 'อัปเดตสำเร็จ']);
}

