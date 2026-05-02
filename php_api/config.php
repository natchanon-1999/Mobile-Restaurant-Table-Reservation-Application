<?php
// =====================================================
// config.php — FIXED VERSION
// แก้ปัญหา: JWT base64url, Authorization header XAMPP,
//            requireAdmin, generateReservationCode
// =====================================================

error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// ─── DATABASE ─────────────────────────
define('DB_HOST',    'localhost');
define('DB_NAME',    'restaurant_db');
define('DB_USER',    'root');
define('DB_PASS',    '');
define('DB_CHARSET', 'utf8mb4');

// ─── JWT ─────────────────────────────
define('JWT_SECRET', 'your_super_secret_key_change_this_2024');
define('JWT_EXPIRE', 86400);

// ─── CORS ────────────────────────────
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// =====================================================
// DATABASE
// =====================================================
function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        try {
            $pdo = new PDO(
                "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=" . DB_CHARSET,
                DB_USER, DB_PASS,
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]
            );
        } catch (PDOException $e) {
            jsonResponse(['success' => false, 'message' => 'DB error: ' . $e->getMessage()], 500);
        }
    }
    return $pdo;
}

// =====================================================
// RESPONSE
// =====================================================
function jsonResponse(array $data, int $code = 200): void {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}

// =====================================================
// REQUEST BODY
// =====================================================
function getRequestBody(): array {
    $json = json_decode(file_get_contents('php://input'), true);
    return is_array($json) ? $json : [];
}

// =====================================================
// JWT base64url
// =====================================================
function base64url_encode(string $data): string {
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64url_decode(string $data): string {
    $r = strlen($data) % 4;
    if ($r) $data .= str_repeat('=', 4 - $r);
    return base64_decode(strtr($data, '-_', '+/'));
}

function generateJWT(array $payload): string {
    $h = base64url_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $p = base64url_encode(json_encode(array_merge($payload, [
        'exp' => time() + JWT_EXPIRE,
        'iat' => time(),
    ])));
    $s = base64url_encode(hash_hmac('sha256', "$h.$p", JWT_SECRET, true));
    return "$h.$p.$s";
}

function verifyJWT(string $token): ?array {
    $parts = explode('.', $token);
    if (count($parts) !== 3) return null;
    [$h, $p, $s] = $parts;

    // ลอง verify ด้วย base64url ก่อน (token ใหม่)
    $ok = hash_equals(base64url_encode(hash_hmac('sha256', "$h.$p", JWT_SECRET, true)), $s);
    // fallback: token เก่าที่สร้างด้วย base64 ธรรมดา
    if (!$ok) {
        $ok = hash_equals(base64_encode(hash_hmac('sha256', "$h.$p", JWT_SECRET, true)), $s);
    }
    if (!$ok) { error_log("[JWT] Bad signature"); return null; }

    // decode payload ลอง base64url ก่อน fallback base64
    $data = json_decode(base64url_decode($p), true)
         ?? json_decode(base64_decode($p), true);

    if (empty($data)) return null;
    if (($data['exp'] ?? 0) < time()) { error_log("[JWT] Expired"); return null; }
    return $data;
}

// =====================================================
// AUTH — รองรับ XAMPP Windows
// =====================================================
function getAuthorizationHeader(): string {
    if (!empty($_SERVER['HTTP_AUTHORIZATION']))          return $_SERVER['HTTP_AUTHORIZATION'];
    if (!empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) return $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    if (function_exists('getallheaders')) {
        foreach (getallheaders() as $k => $v)
            if (strtolower($k) === 'authorization') return $v;
    }
    if (function_exists('apache_request_headers')) {
        foreach (apache_request_headers() as $k => $v)
            if (strtolower($k) === 'authorization') return $v;
    }
    return '';
}

function requireAuth(): array {
    $auth = getAuthorizationHeader();
    if (!str_starts_with($auth, 'Bearer ')) {
        error_log("[AUTH] No Bearer. header='" . substr($auth,0,50) . "'");
        jsonResponse(['success' => false, 'message' => 'Unauthorized'], 401);
    }
    $user = verifyJWT(substr($auth, 7));
    if (!$user) jsonResponse(['success' => false, 'message' => 'Invalid or expired token'], 401);
    return $user;
}

function requireAdmin(): array {
    $user = requireAuth();
    if (($user['role'] ?? '') !== 'admin')
        jsonResponse(['success' => false, 'message' => 'Admin only'], 403);
    return $user;
}

// =====================================================
// HELPERS
// =====================================================
function generateReservationCode(): string {
    $db = getDB();
    do {
        $code = 'RES' . date('ym') . str_pad(rand(0, 99999), 5, '0', STR_PAD_LEFT);
        $stmt = $db->prepare("SELECT COUNT(*) FROM reservations WHERE reservation_code = ?");
        $stmt->execute([$code]);
    } while ((int)$stmt->fetchColumn() > 0);
    return $code;
}

// =====================================================
// ERROR HANDLERS
// =====================================================
set_exception_handler(function ($e) {
    error_log("[EXCEPTION] " . $e->getMessage());
    jsonResponse(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
});

set_error_handler(function ($severity, $message, $file, $line) {
    error_log("[PHP ERROR] $message in $file:$line");
    jsonResponse(['success' => false, 'message' => "PHP Error: $message"], 500);
});
