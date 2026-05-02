<?php
// =====================================================
// reservations.php — จองโต๊ะ / ดูประวัติ / ยกเลิก
// =====================================================
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = trim($_GET['action'] ?? '');
$id     = (int)($_GET['id'] ?? 0);

switch ("$method:$action") {
    case 'GET:list':       handleList();         break;
    case 'GET:my':         handleMy();           break;
    case 'GET:booked':     handleBooked();       break; // ✅ endpoint ใหม่สำหรับ Flutter
    case 'GET:detail':     handleDetail($id);    break;
    case 'GET:search':     handleSearch();       break;
    case 'POST:create':    handleCreate();       break;
    case 'PUT:update':     handleUpdate($id);    break;
    case 'PUT:cancel':     handleCancel($id);    break;
    case 'PUT:status':     handleStatus($id);    break;
    default: jsonResponse(['success' => false, 'message' => 'Route not found'], 404);
}

// ─── List (Admin) ──────────────────────────────────
function handleList(): void {
    requireAdmin();
    $db     = getDB();
    $date   = $_GET['date']   ?? '';
    $status = $_GET['status'] ?? '';
    $page   = max(1, (int)($_GET['page'] ?? 1));
    $limit  = 20;
    $offset = ($page - 1) * $limit;

    $sql    = "SELECT * FROM v_reservation_details WHERE 1=1";
    $params = [];

    if ($date)   { $sql .= " AND reservation_date = ?"; $params[] = $date; }
    if ($status) { $sql .= " AND status = ?";           $params[] = $status; }

    $sql .= " ORDER BY reservation_date DESC, start_time DESC LIMIT $limit OFFSET $offset";

    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    jsonResponse(['success' => true, 'reservations' => $stmt->fetchAll(), 'page' => $page]);
}

// ─── My Reservations ───────────────────────────────
function handleMy(): void {
    $auth   = requireAuth();
    $db     = getDB();
    $status = $_GET['status'] ?? '';
    // ✅ แก้: เพิ่ม limit ใหญ่ขึ้นและ optional — Flutter ใช้หน้าแรกแสดงทั้งหมด
    $page   = max(1, (int)($_GET['page'] ?? 1));
    $limit  = (int)($_GET['limit'] ?? 50); // ✅ default 50 แทน 10
    $limit  = min($limit, 100);            // ✅ cap ที่ 100 กันใหญ่เกิน
    $offset = ($page - 1) * $limit;

    $sql    = "SELECT * FROM v_reservation_details WHERE user_id = ?";
    $params = [$auth['id']];

    if ($status) { $sql .= " AND status = ?"; $params[] = $status; }
    $sql .= " ORDER BY reservation_date DESC, start_time DESC LIMIT $limit OFFSET $offset";

    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    jsonResponse(['success' => true, 'reservations' => $stmt->fetchAll(), 'page' => $page]);
}

// ─── Booked Table IDs (สำหรับ Flutter หน้าเลือกโต๊ะ) ──
// ✅ endpoint ใหม่: คืนแค่ table_id ที่ถูกจองอยู่ (confirmed/pending)
// ตั้งแต่วันนี้เป็นต้นไป — เบา เร็ว ไม่ดึงข้อมูลเกิน
function handleBooked(): void {
    $auth  = requireAuth();
    $db    = getDB();
    $today = date('Y-m-d');

    $stmt = $db->prepare("
        SELECT DISTINCT table_id
        FROM reservations
        WHERE status IN ('confirmed', 'pending')
          AND reservation_date >= ?
    ");
    $stmt->execute([$today]);

    $ids = array_column($stmt->fetchAll(PDO::FETCH_ASSOC), 'table_id');
    // แปลงเป็น int ทั้งหมด
    $ids = array_map('intval', $ids);

    jsonResponse(['success' => true, 'booked_table_ids' => $ids]);
}

// ─── Detail ────────────────────────────────────────
function handleDetail(int $id): void {
    $auth  = requireAuth();
    $db    = getDB();
    $stmt  = $db->prepare("SELECT * FROM v_reservation_details WHERE id = ?");
    $stmt->execute([$id]);
    $res   = $stmt->fetch();

    if (!$res) jsonResponse(['success' => false, 'message' => 'ไม่พบการจอง'], 404);
    if ($auth['role'] !== 'admin' && $res['user_id'] != $auth['id'])
        jsonResponse(['success' => false, 'message' => 'ไม่มีสิทธิ์เข้าถึง'], 403);

    jsonResponse(['success' => true, 'reservation' => $res]);
}

// ─── Search ────────────────────────────────────────
function handleSearch(): void {
    $auth  = requireAuth();
    $db    = getDB();
    $q     = trim($_GET['q'] ?? '');

    if (strlen($q) < 2) jsonResponse(['success' => false, 'message' => 'กรุณากรอกคำค้นหาอย่างน้อย 2 ตัวอักษร'], 400);

    $like = "%$q%";
    if ($auth['role'] === 'admin') {
        $sql = "SELECT * FROM v_reservation_details 
                WHERE reservation_code LIKE ? OR user_name LIKE ? OR user_phone LIKE ? OR table_number LIKE ?
                ORDER BY created_at DESC LIMIT 30";
        $stmt = $db->prepare($sql);
        $stmt->execute([$like, $like, $like, $like]);
    } else {
        $sql = "SELECT * FROM v_reservation_details 
                WHERE user_id = ? AND (reservation_code LIKE ? OR table_number LIKE ?)
                ORDER BY created_at DESC LIMIT 20";
        $stmt = $db->prepare($sql);
        $stmt->execute([$auth['id'], $like, $like]);
    }
    jsonResponse(['success' => true, 'reservations' => $stmt->fetchAll()]);
}

// ─── Create Reservation ────────────────────────────
function handleCreate(): void {
    $auth  = requireAuth();
    $db    = getDB();
    $body  = getRequestBody();

    $tableId  = (int)($body['table_id']      ?? 0);
    $slotId   = (int)($body['slot_id']       ?? 0);
    $date     = $body['date']                ?? '';
    $guests   = (int)($body['guests']        ?? 1);
    $special  = $body['special_request']     ?? '';
    $occasion = $body['occasion']            ?? '';

    if (!$tableId || !$slotId || !$date || !$guests)
        jsonResponse(['success' => false, 'message' => 'ข้อมูลไม่ครบถ้วน'], 400);

    if ($date < date('Y-m-d'))
        jsonResponse(['success' => false, 'message' => 'ไม่สามารถจองวันที่ผ่านมาแล้ว'], 400);

    // Get slot
    $stmtSlot = $db->prepare("SELECT * FROM time_slots WHERE id = ? AND is_active = 1");
    $stmtSlot->execute([$slotId]);
    $slot = $stmtSlot->fetch();
    if (!$slot) jsonResponse(['success' => false, 'message' => 'ช่วงเวลาไม่ถูกต้อง'], 400);

    // Get table
    $stmtTable = $db->prepare("SELECT * FROM `tables` WHERE id = ? AND is_active = 1");
    $stmtTable->execute([$tableId]);
    $table = $stmtTable->fetch();
    if (!$table) jsonResponse(['success' => false, 'message' => 'ไม่พบโต๊ะ'], 404);
    if ($table['capacity'] < $guests)
        jsonResponse(['success' => false, 'message' => "โต๊ะนี้รองรับได้สูงสุด {$table['capacity']} คน"], 400);

    // Check availability
    $checkSql = "SELECT id FROM reservations 
                 WHERE table_id = ? AND reservation_date = ? AND status NOT IN ('cancelled','no_show')
                 AND ((start_time < ? AND end_time > ?) OR (start_time >= ? AND start_time < ?))";
    $stmtCheck = $db->prepare($checkSql);
    $stmtCheck->execute([
        $tableId, $date,
        $slot['end_time'], $slot['start_time'],
        $slot['start_time'], $slot['end_time']
    ]);
    if ($stmtCheck->fetch())
        jsonResponse(['success' => false, 'message' => 'โต๊ะนี้ถูกจองไปแล้วในช่วงเวลาที่เลือก'], 409);

    // Insert
    $code = generateReservationCode();
    $stmt = $db->prepare("INSERT INTO reservations 
        (reservation_code, user_id, table_id, guest_count, reservation_date, start_time, end_time, status, special_request, occasion)
        VALUES (?,?,?,?,?,?,?,?,?,?)");
    $stmt->execute([
        $code, $auth['id'], $tableId, $guests, $date,
        $slot['start_time'], $slot['end_time'], 'confirmed',
        $special, $occasion
    ]);
    $resId = $db->lastInsertId();

    jsonResponse([
        'success'          => true,
        'message'          => 'จองโต๊ะสำเร็จ!',
        'reservation_id'   => $resId,
        'reservation_code' => $code
    ], 201);
}

// ─── Update Reservation ────────────────────────────
function handleUpdate(int $id): void {
    $auth  = requireAuth();
    $db    = getDB();
    $body  = getRequestBody();

    $stmt = $db->prepare("SELECT * FROM reservations WHERE id = ?");
    $stmt->execute([$id]);
    $res = $stmt->fetch();
    if (!$res) jsonResponse(['success' => false, 'message' => 'ไม่พบการจอง'], 404);
    if ($auth['role'] !== 'admin' && $res['user_id'] != $auth['id'])
        jsonResponse(['success' => false, 'message' => 'ไม่มีสิทธิ์แก้ไข'], 403);
    if ($res['status'] === 'cancelled')
        jsonResponse(['success' => false, 'message' => 'การจองถูกยกเลิกแล้ว'], 400);

    $special  = $body['special_request'] ?? $res['special_request'];
    $occasion = $body['occasion']        ?? $res['occasion'];
    $notes    = $body['notes']           ?? $res['notes'];

    $stmt = $db->prepare("UPDATE reservations SET special_request=?, occasion=?, notes=? WHERE id=?");
    $stmt->execute([$special, $occasion, $notes, $id]);
    jsonResponse(['success' => true, 'message' => 'อัปเดตการจองสำเร็จ']);
}

// ─── Cancel Reservation ────────────────────────────
function handleCancel(int $id): void {
    $auth  = requireAuth();
    $db    = getDB();

    $stmt = $db->prepare("SELECT * FROM reservations WHERE id = ?");
    $stmt->execute([$id]);
    $res = $stmt->fetch();
    if (!$res) jsonResponse(['success' => false, 'message' => 'ไม่พบการจอง'], 404);
    if ($auth['role'] !== 'admin' && $res['user_id'] != $auth['id'])
        jsonResponse(['success' => false, 'message' => 'ไม่มีสิทธิ์ยกเลิก'], 403);
    if (in_array($res['status'], ['cancelled', 'completed']))
        jsonResponse(['success' => false, 'message' => 'ไม่สามารถยกเลิกได้'], 400);

    $stmt = $db->prepare("UPDATE reservations SET status='cancelled' WHERE id=?");
    $stmt->execute([$id]);
    jsonResponse(['success' => true, 'message' => 'ยกเลิกการจองสำเร็จ']);
}

// ─── Update Status (Admin) ─────────────────────────
function handleStatus(int $id): void {
    requireAdmin();
    $db     = getDB();
    $body   = getRequestBody();
    $status = $body['status'] ?? '';

    $allowed = ['pending', 'confirmed', 'cancelled', 'completed', 'no_show'];
    if (!in_array($status, $allowed))
        jsonResponse(['success' => false, 'message' => 'สถานะไม่ถูกต้อง'], 400);

    $stmt = $db->prepare("UPDATE reservations SET status=? WHERE id=?");
    $stmt->execute([$status, $id]);
    jsonResponse(['success' => true, 'message' => 'อัปเดตสถานะสำเร็จ']);
}
