// lib/screens/tables/tables_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../booking/booking_screen.dart';

class TablesScreen extends StatefulWidget {
  final bool adminMode;
  final String? filterZone;
  const TablesScreen({super.key, this.adminMode = false, this.filterZone});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen>
    with SingleTickerProviderStateMixin {
  List<TableModel> _tables = [];
  Set<int> _bookedTableIds = {};
  bool _loading = true;
  String _selectedZone = 'all';
  late TabController _tabCtrl;

  final _zones = ['all', 'indoor', 'outdoor', 'vip', 'rooftop'];
  final _zoneLabels = {
    'all': 'ทั้งหมด',
    'indoor': 'Indoor',
    'outdoor': 'Outdoor',
    'vip': 'VIP',
    'rooftop': 'Rooftop',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _zones.length, vsync: this);

    if (widget.filterZone != null) {
      final idx = _zones.indexOf(widget.filterZone!);
      if (idx >= 0) {
        _selectedZone = widget.filterZone!;
        _tabCtrl.index = idx;
      }
    }

    _loadAll();

    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _selectedZone = _zones[_tabCtrl.index]);
        _loadAll();
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final zone = _selectedZone == 'all' ? null : _selectedZone;

    List<TableModel> tables = [];
    Set<int> booked = <int>{};

    try {
      tables = await ApiService.getTables(zone: zone);
    } catch (e) {
      print("LOAD TABLES ERROR: $e");
    }

    try {
      booked = await ApiService.getBookedTableIds();
    } catch (e) {
      print("LOAD BOOKED ERROR: $e");
      booked = <int>{};
    }

    if (mounted) {
      setState(() {
        _tables = tables;
        _bookedTableIds = booked;
        _loading = false;
      });
    }
  }

  Future<void> _goToBooking(TableModel table) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingScreen(table: table)),
    );
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final effectiveAdmin = widget.adminMode || isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(effectiveAdmin ? 'จัดการโต๊ะ' : 'เลือกโต๊ะ'),
        actions: [
          if (effectiveAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
              onPressed: _showAddTableDialog,
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.gold,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.kanit(fontWeight: FontWeight.w600),
          tabs: _zones.map((z) => Tab(text: _zoneLabels[z])).toList(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.gold))
          : _tables.isEmpty
              ? const EmptyState(
                  icon: Icons.table_restaurant_outlined,
                  title: 'ไม่พบโต๊ะ',
                  subtitle: 'ไม่มีโต๊ะในโซนนี้ขณะนี้',
                )
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _loadAll,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: _tables.length,
                    itemBuilder: (ctx, i) {
                      final table = _tables[i];
                      final isBooked = table.id != null &&
                          _bookedTableIds.contains(table.id);
                      return _TableCard(
                        table: table,
                        isBooked: isBooked,
                        adminMode: effectiveAdmin,
                        onTap: effectiveAdmin
                            ? null
                            : isBooked
                                ? null
                                : () => _goToBooking(table),
                        onEdit: () => _showEditDialog(table),
                        onDelete: () => _deleteTable(table),
                      );
                    },
                  ),
                ),
    );
  }

  void _showAddTableDialog() => _showTableDialog(null);
  void _showEditDialog(TableModel table) => _showTableDialog(table);

  void _showTableDialog(TableModel? existing) {
    final numCtrl = TextEditingController(text: existing?.tableNumber ?? '');
    final capCtrl =
        TextEditingController(text: existing?.capacity.toString() ?? '2');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final imgCtrl = TextEditingController(text: existing?.imageUrl ?? '');
    String zone = existing?.zone ?? 'indoor';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'เพิ่มโต๊ะใหม่' : 'แก้ไขโต๊ะ',
                  style: GoogleFonts.kanit(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: numCtrl,
                  style: GoogleFonts.kanit(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'หมายเลขโต๊ะ (เช่น T01)',
                    prefixIcon: Icon(Icons.table_restaurant_outlined,
                        color: AppColors.textHint),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.kanit(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'ความจุ (คน)',
                    prefixIcon:
                        Icon(Icons.people_outline, color: AppColors.textHint),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: GoogleFonts.kanit(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'คำอธิบาย',
                    prefixIcon: Icon(Icons.notes_outlined,
                        color: AppColors.textHint),
                  ),
                ),
                const SizedBox(height: 12),
                // ── URL รูปภาพ + Live Preview ──
                StatefulBuilder(builder: (ctx2, setPreview) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: imgCtrl,
                        style:
                            GoogleFonts.kanit(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'URL รูปภาพโต๊ะ',
                          hintText: 'https://...',
                          prefixIcon: Icon(Icons.image_outlined,
                              color: AppColors.textHint),
                        ),
                        onChanged: (_) => setPreview(() {}),
                      ),
                      if (imgCtrl.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imgCtrl.text.trim(),
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    color: AppColors.textHint),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: zone,
                  dropdownColor: AppColors.surfaceAlt,
                  style: GoogleFonts.kanit(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'โซน',
                    prefixIcon: Icon(Icons.location_on_outlined,
                        color: AppColors.textHint),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'indoor', child: Text('Indoor')),
                    DropdownMenuItem(value: 'outdoor', child: Text('Outdoor')),
                    DropdownMenuItem(value: 'vip', child: Text('VIP')),
                    DropdownMenuItem(value: 'rooftop', child: Text('Rooftop')),
                  ],
                  onChanged: (v) => setModalState(() => zone = v!),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final body = {
                      'table_number': numCtrl.text.trim(),
                      'capacity': int.tryParse(capCtrl.text) ?? 2,
                      'zone': zone,
                      'description': descCtrl.text.trim(),
                      'image_url': imgCtrl.text.trim(),
                    };
                    Map<String, dynamic> res;
                    if (existing == null) {
                      res = await ApiService.createTable(body);
                    } else {
                      res = await ApiService.updateTable(existing.id, body);
                    }
                    if (context.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message'] ?? '',
                              style: GoogleFonts.kanit()),
                          backgroundColor: res['success'] == true
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      );
                      _loadAll();
                    }
                  },
                  child: Text(existing == null ? 'เพิ่มโต๊ะ' : 'บันทึก'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<void> _deleteTable(TableModel table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('ยืนยันการลบ',
            style: GoogleFonts.kanit(color: AppColors.textPrimary)),
        content: Text('ต้องการลบโต๊ะ ${table.tableNumber}?',
            style: GoogleFonts.kanit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ApiService.deleteTable(table.id);
      _loadAll();
    }
  }
}

// ─── Table Card ───────────────────────────────────
class _TableCard extends StatelessWidget {
  final TableModel table;
  final bool isBooked;
  final bool adminMode;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TableCard({
    required this.table,
    required this.isBooked,
    this.adminMode = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Widget _imagePlaceholder(Color color) {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.18), color.withOpacity(0.05)],
        ),
      ),
      child: Center(
        child: Icon(Icons.table_restaurant_outlined,
            color: color.withOpacity(0.45), size: 38),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zoneColors = {
      'indoor': AppColors.indoor,
      'outdoor': AppColors.outdoor,
      'vip': AppColors.vip,
      'rooftop': AppColors.rooftop,
    };
    final color = zoneColors[table.zone] ?? AppColors.gold;
    final borderColor =
        isBooked ? AppColors.error.withOpacity(0.5) : color.withOpacity(0.3);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isBooked ? 0.7 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── รูปภาพโต๊ะ ──
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: (table.imageUrl != null &&
                              table.imageUrl!.isNotEmpty)
                          ? Image.network(
                              table.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _imagePlaceholder(color),
                            )
                          : _imagePlaceholder(color),
                    ),
                    // gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.card, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // badge สถานะ
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isBooked
                                  ? AppColors.error
                                  : AppColors.success)
                              .withOpacity(0.88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isBooked ? 'ถูกจอง' : 'ว่าง',
                              style: GoogleFonts.kanit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── ข้อมูลโต๊ะ ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'โต๊ะ ${table.tableNumber}',
                        style: GoogleFonts.kanit(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 3),
                      ZoneBadge(table.zone),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.people_outline,
                            color: AppColors.textHint, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${table.capacity} คน',
                          style: GoogleFonts.kanit(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ]),
                      if (table.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          table.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.kanit(
                              color: AppColors.textHint, fontSize: 10),
                        ),
                      ],
                      if (adminMode) ...[
                        const Spacer(),
                        Row(children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.gold, size: 17),
                            onPressed: onEdit,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 17),
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
