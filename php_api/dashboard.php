<?php
// =====================================================
// dashboard.php — Admin Dashboard Stats
// =====================================================
require_once 'config.php';

$method = $_SERVER['REQUEST_METHOD'];
$action = trim($_GET['action'] ?? '');

switch ("$method:$action") {
    case 'GET:stats': handleStats(); break;
    case 'GET:today': handleToday(); break;
    default: jsonResponse(['success' => false, 'message' => 'Route not found'], 404);
}

function handleStats(): void {
    requireAdmin();
    $db   = getDB();
    $today = date('Y-m-d');

    // Total counts
    $stmtTotalTables = $db->query("SELECT COUNT(*) FROM `tables` WHERE is_active = 1");
    $stmtTotalUsers  = $db->query("SELECT COUNT(*) FROM users WHERE role = 'customer'");
    $stmtTodayRes    = $db->prepare("SELECT COUNT(*) FROM reservations WHERE reservation_date = ? AND status NOT IN ('cancelled','no_show')");
    $stmtTodayRes->execute([$today]);
    $stmtMonthRes    = $db->prepare("SELECT COUNT(*) FROM reservations WHERE DATE_FORMAT(reservation_date,'%Y-%m') = ? AND status NOT IN ('cancelled')");
    $stmtMonthRes->execute([date('Y-m')]);

    // Status breakdown today
    $stmtStatus = $db->prepare("SELECT status, COUNT(*) as cnt FROM reservations WHERE reservation_date = ? GROUP BY status");
    $stmtStatus->execute([$today]);
    $statusBreakdown = [];
    foreach ($stmtStatus->fetchAll() as $row) $statusBreakdown[$row['status']] = $row['cnt'];

    // Upcoming today
    $stmtUpcoming = $db->prepare("SELECT * FROM v_reservation_details WHERE reservation_date = ? AND status = 'confirmed' ORDER BY start_time ASC LIMIT 10");
    $stmtUpcoming->execute([$today]);

    jsonResponse([
        'success'         => true,
        'total_tables'    => (int)$stmtTotalTables->fetchColumn(),
        'total_customers' => (int)$stmtTotalUsers->fetchColumn(),
        'today_reservations' => (int)$stmtTodayRes->fetchColumn(),
        'month_reservations' => (int)$stmtMonthRes->fetchColumn(),
        'status_breakdown'   => $statusBreakdown,
        'upcoming_today'     => $stmtUpcoming->fetchAll(),
    ]);
}

function handleToday(): void {
    requireAdmin();
    $db    = getDB();
    $today = date('Y-m-d');
    $stmt  = $db->prepare("SELECT * FROM v_reservation_details WHERE reservation_date = ? ORDER BY start_time ASC");
    $stmt->execute([$today]);
    jsonResponse(['success' => true, 'date' => $today, 'reservations' => $stmt->fetchAll()]);
}
