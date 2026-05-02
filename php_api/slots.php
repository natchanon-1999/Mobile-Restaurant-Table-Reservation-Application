<?php
// =====================================================
// slots.php — ช่วงเวลาการจอง
// =====================================================
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = trim($_GET['action'] ?? '');

switch ("$method:$action") {
    case 'GET:list': handleList(); break;
    default: jsonResponse(['success' => false, 'message' => 'Route not found'], 404);
}

function handleList(): void {
    $db   = getDB();
    $stmt = $db->query("SELECT * FROM time_slots WHERE is_active = 1 ORDER BY start_time");
    jsonResponse(['success' => true, 'slots' => $stmt->fetchAll()]);
}
