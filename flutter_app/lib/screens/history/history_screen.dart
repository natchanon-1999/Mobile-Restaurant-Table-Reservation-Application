// lib/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class HistoryScreen extends StatefulWidget {
  final bool adminMode;
  const HistoryScreen({super.key, this.adminMode = false});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  List<ReservationModel> _reservations = [];
  List<ReservationModel> _searchResults = [];
  bool _loading = false;
  bool _searching = false;
  String _selectedStatus = '';

  final _statusFilters = {
    '': 'ทั้งหมด',
    'confirmed': 'ยืนยัน',
    // 'pending': 'รอยืนยัน',
    'cancelled': 'ยกเลิก',
    'completed': 'เสร็จสิ้น',
  };

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _loading = true);
    final isAdmin = widget.adminMode || context.read<AuthProvider>().isAdmin;
    List<ReservationModel> list;
    if (isAdmin) {
      list = await ApiService.getAllReservations(
          status: _selectedStatus.isEmpty ? null : _selectedStatus);
    } else {
      list = await ApiService.getMyReservations(
          status: _selectedStatus.isEmpty ? null : _selectedStatus);
    }
    if (mounted) setState(() { _reservations = list; _loading = false; });
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() { _searching = false; _searchResults = []; });
      return;
    }
    setState(() => _searching = true);
    final results = await ApiService.searchReservations(q.trim());
    if (mounted) setState(() { _searchResults = results; _searching = false; });
  }

  Future<void> _cancelReservation(ReservationModel res) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ยืนยันยกเลิก',
            style: GoogleFonts.kanit(color: AppColors.textPrimary)),
        content: Text('ต้องการยกเลิกการจอง ${res.reservationCode}?',
            style: GoogleFonts.kanit(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('ไม่', style: GoogleFonts.kanit(color: AppColors.textSecondary))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('ยกเลิกการจอง',
                  style: GoogleFonts.kanit(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await ApiService.cancelReservation(res.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? '', style: GoogleFonts.kanit()),
          backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
        ));
        _loadReservations();
      }
    }
  }

  Future<void> _updateStatus(ReservationModel res, String status) async {
    final result = await ApiService.updateReservationStatus(res.id, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? '', style: GoogleFonts.kanit()),
        backgroundColor: result['success'] == true ? AppColors.success : AppColors.error,
      ));
      _loadReservations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        widget.adminMode || context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'การจองทั้งหมด' : 'ประวัติการจอง'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.gold,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.kanit(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'รายการจอง'),
            Tab(text: 'ค้นหา'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildListTab(isAdmin),
          _buildSearchTab(),
        ],
      ),
    );
  }

  // ─── Tab 1: Reservation List ───────────────────
  Widget _buildListTab(bool isAdmin) {
    return Column(
      children: [
        // Status filter chips
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.entries.map((e) {
                final sel = _selectedStatus == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedStatus = e.key);
                      _loadReservations();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.gold
                            : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppColors.gold : AppColors.border,
                        ),
                      ),
                      child: Text(
                        e.value,
                        style: GoogleFonts.kanit(
                          color: sel ? AppColors.bg : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.gold))
              : _reservations.isEmpty
                  ? EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'ไม่มีการจอง',
                      subtitle: _selectedStatus.isEmpty
                          ? 'คุณยังไม่มีประวัติการจอง'
                          : 'ไม่มีการจองในสถานะนี้',
                    )
                  : RefreshIndicator(
                      color: AppColors.gold,
                      onRefresh: _loadReservations,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reservations.length,
                        itemBuilder: (ctx, i) {
                          final res = _reservations[i];
                          return isAdmin
                              ? _AdminReservationCard(
                                  reservation: res,
                                  onStatusChange: (status) =>
                                      _updateStatus(res, status),
                                )
                              : ReservationCard(
                                  reservation: res,
                                  onCancel: res.status == 'confirmed'
                                      ? () => _cancelReservation(res)
                                      : null,
                                );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // ─── Tab 2: Search ─────────────────────────────
  Widget _buildSearchTab() {
    final isAdmin =
        widget.adminMode || context.read<AuthProvider>().isAdmin;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.kanit(color: AppColors.textPrimary),
            onChanged: _search,
            decoration: InputDecoration(
              hintText: isAdmin
                  ? 'ค้นหา รหัสจอง / ชื่อลูกค้า / เบอร์โทร / โต๊ะ'
                  : 'ค้นหา รหัสจอง / หมายเลขโต๊ะ',
              prefixIcon:
                  const Icon(Icons.search_outlined, color: AppColors.textHint),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textHint),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() {
                          _searchResults = [];
                          _searching = false;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: _searching
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.gold))
              : _searchCtrl.text.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          const Icon(Icons.search,
                              color: AppColors.textHint, size: 60),
                          const SizedBox(height: 12),
                          Text('พิมพ์เพื่อค้นหา',
                              style: GoogleFonts.kanit(
                                  color: AppColors.textSecondary)),
                        ]))
                  : _searchResults.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_outlined,
                          title: 'ไม่พบผลลัพธ์',
                          subtitle: 'ลองค้นหาด้วยคำอื่น')
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _searchResults.length,
                          itemBuilder: (ctx, i) {
                            final res = _searchResults[i];
                            return isAdmin
                                ? _AdminReservationCard(
                                    reservation: res,
                                    onStatusChange: (status) =>
                                        _updateStatus(res, status),
                                  )
                                : ReservationCard(
                                    reservation: res,
                                    onCancel: res.status == 'confirmed'
                                        ? () => _cancelReservation(res)
                                        : null,
                                  );
                          },
                        ),
        ),
      ],
    );
  }
}

// ─── Admin Reservation Card ───────────────────────
class _AdminReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final Function(String) onStatusChange;

  const _AdminReservationCard(
      {required this.reservation, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    final res = reservation;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(res.reservationCode,
                      style: GoogleFonts.sourceCodePro(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  Text(res.userName,
                      style: GoogleFonts.kanit(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                  Text(res.userPhone,
                      style: GoogleFonts.kanit(
                          color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
              StatusBadge(res.status),
            ]),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _info(Icons.table_restaurant_outlined,
                        'โต๊ะ ${res.tableNumber}'),
                    const SizedBox(height: 4),
                    _info(Icons.calendar_today_outlined, res.displayDate),
                    const SizedBox(height: 4),
                    _info(Icons.access_time_outlined, res.displayTime),
                    const SizedBox(height: 4),
                    _info(Icons.people_outline, '${res.guestCount} คน'),
                  ]),
                ),
                // Status change dropdown
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: res.status,
                      dropdownColor: AppColors.surfaceAlt,
                      style: GoogleFonts.kanit(
                          color: AppColors.textPrimary, fontSize: 12),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textHint, size: 16),
                      items: const [
                        DropdownMenuItem(
                            value: 'confirmed',
                            child: Text('ยืนยัน')),
                        // DropdownMenuItem(
                        //     value: 'pending', child: Text('รอยืนยัน')),
                        DropdownMenuItem(
                            value: 'completed', child: Text('เสร็จสิ้น')),
                        DropdownMenuItem(
                            value: 'no_show', child: Text('ไม่มา')),
                        DropdownMenuItem(
                            value: 'cancelled', child: Text('ยกเลิก')),
                      ],
                      onChanged: (v) {
                        if (v != null && v != res.status) {
                          onStatusChange(v);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (res.specialRequest.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(children: [
                const Icon(Icons.notes_outlined,
                    color: AppColors.textHint, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(res.specialRequest,
                      style: GoogleFonts.kanit(
                          color: AppColors.textHint, fontSize: 12)),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(children: [
        Icon(icon, color: AppColors.gold, size: 13),
        const SizedBox(width: 6),
        Text(text,
            style:
                GoogleFonts.kanit(color: AppColors.textSecondary, fontSize: 12)),
      ]);
}
