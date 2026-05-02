// lib/models/models.dart
// =====================================================
// Data Models
// =====================================================

// Helper: รองรับทั้ง int และ String จาก PHP
int _toInt(dynamic v) => int.parse(v.toString());

class TableModel {
  final int id;
  final String tableNumber;
  final int capacity;
  final String zone;
  final String description;
  final bool isActive;
  bool? isAvailable;
  final String? imageUrl;

  TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.zone,
    required this.description,
    required this.isActive,
    this.isAvailable,
    this.imageUrl,
  });

  factory TableModel.fromJson(Map<String, dynamic> j) => TableModel(
    id: _toInt(j['id']),
    tableNumber: j['table_number'],
    capacity: _toInt(j['capacity']),
    zone: j['zone'],
    description: j['description'] ?? '',
    isActive: j['is_active'] == 1 || j['is_active'] == true || j['is_active'] == '1',
    isAvailable: j['is_available'] != null
        ? (j['is_available'] == 1 || j['is_available'] == true || j['is_available'] == '1')
        : null,
    imageUrl: j['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'table_number': tableNumber,
    'capacity': capacity,
    'zone': zone,
    'description': description,
    'is_active': isActive ? 1 : 0,
    'image_url': imageUrl,
  };
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: _toInt(j['id']),
    name: j['name'],
    email: j['email'],
    phone: j['phone'],
    role: j['role'],
    avatarUrl: j['avatar_url'],
  );

  bool get isAdmin => role == 'admin';
}

class TimeSlot {
  final int id;
  final String slotName;
  final String startTime;
  final String endTime;

  TimeSlot({
    required this.id,
    required this.slotName,
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> j) => TimeSlot(
    id: _toInt(j['id']),
    slotName: j['slot_name'],
    startTime: j['start_time'],
    endTime: j['end_time'],
  );

  String get displayTime => '${startTime.substring(0,5)} – ${endTime.substring(0,5)}';
}

class ReservationModel {
  final int id;
  final String reservationCode;
  final int userId;
  final String userName;
  final String userPhone;
  final int tableId;
  final String tableNumber;
  final String zone;
  final int capacity;
  final int guestCount;
  final String reservationDate;
  final String startTime;
  final String endTime;
  String status;
  final String specialRequest;
  final String occasion;
  final String createdAt;

  ReservationModel({
    required this.id,
    required this.reservationCode,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.tableId,
    required this.tableNumber,
    required this.zone,
    required this.capacity,
    required this.guestCount,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.specialRequest,
    required this.occasion,
    required this.createdAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> j) => ReservationModel(
    id: _toInt(j['id']),
    reservationCode: j['reservation_code'],
    userId: _toInt(j['user_id']),
    userName: j['user_name'] ?? '',
    userPhone: j['user_phone'] ?? '',
    tableId: _toInt(j['table_id']),
    tableNumber: j['table_number'],
    zone: j['zone'] ?? '',
    capacity: _toInt(j['capacity'] ?? 0),
    guestCount: _toInt(j['guest_count']),
    reservationDate: j['reservation_date'],
    startTime: j['start_time'],
    endTime: j['end_time'],
    status: j['status'],
    specialRequest: j['special_request'] ?? '',
    occasion: j['occasion'] ?? '',
    createdAt: j['created_at'],
  );

  String get displayDate {
    try {
      final parts = reservationDate.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) { return reservationDate; }
  }

  String get displayTime => '${startTime.substring(0,5)} – ${endTime.substring(0,5)}';

  bool get isUpcoming {
    try {
      final d = DateTime.parse(reservationDate);
      return d.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    } catch (_) { return false; }
  }
}
