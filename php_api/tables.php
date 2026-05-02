<?php
// =====================================================
// tables.php — CRUD โต๊ะอาหาร
// =====================================================
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = trim($_GET['action'] ?? '');
$id     = (int)($_GET['id'] ?? 0);

switch ("$method:$action") {
    case 'GET:list':       handleList();              break;
    case 'GET:detail':     handleDetail($id);         break;
    case 'GET:availability': handleAvailability();   break;
    case 'POST:create':    handleCreate();            break;
    case 'PUT:update':     handleUpdate($id);         break;
    case 'DELETE:delete':  handleDelete($id);         break;
    default: jsonResponse(['success' => false, 'message' => 'Route not found'], 404);
}

// ─── List Tables ───────────────────────────────────
function handleList(): void {
    $db   = getDB();
    $zone = $_GET['zone'] ?? '';
    $sql  = "SELECT * FROM `tables` WHERE is_active = 1";
    $params = [];
    if ($zone) { $sql .= " AND zone = ?"; $params[] = $zone; }
    $sql .= " ORDER BY table_number ASC";
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    jsonResponse(['success' => true, 'tables' => $stmt->fetchAll()]);
}

// ─── Detail ────────────────────────────────────────
function handleDetail(int $id): void {
    $db   = getDB();
    $stmt = $db->prepare("SELECT * FROM `tables` WHERE id = ? AND is_active = 1");
    $stmt->execute([$id]);
    $table = $stmt->fetch();
    if (!$table) jsonResponse(['success' => false, 'message' => 'ไม่พบโต๊ะ'], 404);
    jsonResponse(['success' => true, 'table' => $table]);
}

// ─── Check Availability ────────────────────────────
function handleAvailability(): void {
    $db   = getDB();
    $date = $_GET['date']       ?? '';
    $slot = (int)($_GET['slot_id'] ?? 0);
    $guests = (int)($_GET['guests'] ?? 1);

    if (!$date || !$slot) jsonResponse(['success' => false, 'message' => 'กรุณาระบุวันที่และช่วงเวลา'], 400);

    // Get time slot info
    $stmtSlot = $db->prepare("SELECT * FROM time_slots WHERE id = ? AND is_active = 1");
    $stmtSlot->execute([$slot]);
    $slotData = $stmtSlot->fetch();
    if (!$slotData) jsonResponse(['success' => false, 'message' => 'ไม่พบช่วงเวลานี้'], 404);

    // Tables that are NOT booked at this date/time and have enough capacity
    $sql = "SELECT t.*, 
                CASE WHEN r.id IS NOT NULL THEN 0 ELSE 1 END AS is_available
            FROM `tables` t
            LEFT JOIN reservations r ON r.table_id = t.id
                AND r.reservation_date = ?
                AND r.status NOT IN ('cancelled','no_show')
                AND (
                    (r.start_time < ? AND r.end_time > ?) OR
                    (r.start_time >= ? AND r.start_time < ?)
                )
            WHERE t.is_active = 1 AND t.capacity >= ?
            ORDER BY t.zone, t.capacity ASC";

    $stmt = $db->prepare($sql);
    $stmt->execute([
        $date,
        $slotData['end_time'], $slotData['start_time'],
        $slotData['start_time'], $slotData['end_time'],
        $guests
    ]);
    $tables = $stmt->fetchAll();

    jsonResponse([
        'success'   => true,
        'date'      => $date,
        'slot'      => $slotData,
        'guests'    => $guests,
        'tables'    => $tables
    ]);
}

// ─── Create (Admin) ────────────────────────────────
function handleCreate(): void {
    requireAdmin();
    $db   = getDB();
    $body = getRequestBody();

    $number = trim($body['table_number'] ?? '');
    $cap    = (int)($body['capacity']    ?? 2);
    $zone   = $body['zone']              ?? 'indoor';
    $desc   = $body['description']       ?? '';
    $img    = trim($body['image_url']    ?? '');

    if (!$number) jsonResponse(['success' => false, 'message' => 'กรุณาระบุหมายเลขโต๊ะ'], 400);

    // Check duplicate
    $stmt = $db->prepare("SELECT id FROM `tables` WHERE table_number = ?");
    $stmt->execute([$number]);
    if ($stmt->fetch()) jsonResponse(['success' => false, 'message' => 'หมายเลขโต๊ะนี้มีอยู่แล้ว'], 409);

    $stmt = $db->prepare("INSERT INTO `tables` (table_number, capacity, zone, description, image_url) VALUES (?,?,?,?,?)");
    $stmt->execute([$number, $cap, $zone, $desc, $img]);
    jsonResponse(['success' => true, 'message' => 'เพิ่มโต๊ะสำเร็จ', 'id' => $db->lastInsertId()], 201);
}

// ─── Update (Admin) ────────────────────────────────
function handleUpdate(int $id): void {
    requireAdmin();
    $db   = getDB();
    $body = getRequestBody();

    $number = trim($body['table_number'] ?? '');
    $cap    = (int)($body['capacity']    ?? 2);
    $zone   = $body['zone']              ?? 'indoor';
    $desc   = $body['description']       ?? '';
    $active = (int)($body['is_active']   ?? 1);
    $img    = trim($body['image_url']    ?? '');

    $stmt = $db->prepare("UPDATE `tables` SET table_number=?, capacity=?, zone=?, description=?, is_active=?, image_url=? WHERE id=?");
    $stmt->execute([$number, $cap, $zone, $desc, $active, $img, $id]);
    jsonResponse(['success' => true, 'message' => 'อัปเดตโต๊ะสำเร็จ']);
}

// ─── Delete (Admin) ────────────────────────────────
function handleDelete(int $id): void {
    requireAdmin();
    $db = getDB();
    // Soft delete
    $stmt = $db->prepare("UPDATE `tables` SET is_active = 0 WHERE id = ?");
    $stmt->execute([$id]);
    jsonResponse(['success' => true, 'message' => 'ลบโต๊ะสำเร็จ']);
}
