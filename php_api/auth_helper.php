<?php
// php_api/auth_helper.php
// =====================================================
// วางทับไฟล์เดิม — รองรับ JWT + Apache XAMPP
// =====================================================

/**
 * ดึง Bearer token จาก Authorization header
 * รองรับ XAMPP/Apache ที่ strip header ออก
 */
function getBearerToken(): ?string {
    // วิธีที่ 1: getallheaders()
    if (function_exists('getallheaders')) {
        foreach (getallheaders() as $key => $value) {
            if (strtolower($key) === 'authorization') {
                return extractBearer($value);
            }
        }
    }
    // วิธีที่ 2: $_SERVER['HTTP_AUTHORIZATION']
    if (!empty($_SERVER['HTTP_AUTHORIZATION'])) {
        return extractBearer($_SERVER['HTTP_AUTHORIZATION']);
    }
    // วิธีที่ 3: REDIRECT_ prefix (Apache mod_rewrite)
    if (!empty($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        return extractBearer($_SERVER['REDIRECT_HTTP_AUTHORIZATION']);
    }
    // วิธีที่ 4: apache_request_headers()
    if (function_exists('apache_request_headers')) {
        foreach (apache_request_headers() as $key => $value) {
            if (strtolower($key) === 'authorization') {
                return extractBearer($value);
            }
        }
    }
    return null;
}

function extractBearer(string $header): ?string {
    if (preg_match('/Bearer\s+(.+)/i', $header, $matches)) {
        return trim($matches[1]);
    }
    return null;
}

/**
 * Decode JWT payload (ไม่ verify signature — เชื่อ token ที่ได้จาก login)
 * แล้วเช็ค expiry + หา user จาก DB
 */
function validateToken(): ?int {
    $token = getBearerToken();
    if (empty($token)) {
        error_log("[AUTH] No token found in request");
        return null;
    }

    // Decode JWT payload (base64url)
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        error_log("[AUTH] Invalid JWT format");
        return null;
    }

    try {
        $payload = json_decode(base64url_decode($parts[1]), true);
    } catch (Exception $e) {
        error_log("[AUTH] JWT decode error: " . $e->getMessage());
        return null;
    }

    if (empty($payload)) {
        error_log("[AUTH] Empty JWT payload");
        return null;
    }

    // เช็ค expiry
    if (!empty($payload['exp']) && $payload['exp'] < time()) {
        error_log("[AUTH] Token expired");
        return null;
    }

    // ดึง user_id จาก payload
    $userId = isset($payload['id']) ? (int)$payload['id'] : null;
    if (!$userId) {
        error_log("[AUTH] No user id in payload: " . json_encode($payload));
        return null;
    }

    // ตรวจว่า user มีอยู่ใน DB
    global $pdo;
    $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ? LIMIT 1");
    $stmt->execute([$userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        error_log("[AUTH] User $userId not found in DB");
        return null;
    }

    return (int)$user['id'];
}

function base64url_decode(string $data): string {
    $remainder = strlen($data) % 4;
    if ($remainder) {
        $data .= str_repeat('=', 4 - $remainder);
    }
    return base64_decode(strtr($data, '-_', '+/'));
}

/**
 * ส่ง JSON response และจบ
 */
function jsonResponse(array $data, int $code = 200): void {
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

/**
 * บังคับ auth — คืน user_id หรือ die 401
 */
function requireAuth(): int {
    $userId = validateToken();
    if ($userId === null) {
        jsonResponse(['success' => false, 'message' => 'Unauthorized'], 401);
    }
    return $userId;
}

// Handle CORS preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
    http_response_code(200);
    exit;
}
