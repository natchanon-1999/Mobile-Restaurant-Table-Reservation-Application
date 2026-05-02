// lib/screens/booking/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class BookingScreen extends StatefulWidget {
  final TableModel? table;
  const BookingScreen({super.key, this.table});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Step 1: Date & Slot & Guests
  DateTime _selectedDate =
      DateTime.now().add(const Duration(days: 1));
  TimeSlot? _selectedSlot;
  List<TimeSlot> _slots = [];

  // Step 2: Table selection (ข้ามได้ถ้า table ถูกส่งมาแล้ว)
  TableModel? _selectedTable;
  List<TableModel> _availableTables = [];
  bool _checkingAvail = false;

  // Step 3: Details
  int _guestCount = 2;
  String _occasion = '';
  final _specialCtrl = TextEditingController();

  int _step = 0;
  bool _loading = false;

  // ถ้า table ถูกส่งมา จะมีแค่ 2 steps (date+slot → confirm)
  // ถ้าไม่มี table จะมี 3 steps (date+slot → pick table → confirm)
  bool get _hasPreselectedTable => widget.table != null;

  final _occasions = {
    '': 'ไม่มีโอกาสพิเศษ',
    'birthday': '🎂 วันเกิด',
    'anniversary': '💍 ครบรอบ',
    'business': '💼 ธุรกิจ',
    'date': '❤️ เดต',
    'family': '👨‍👩‍👧 ครอบครัว',
  };

  @override
  void initState() {
    super.initState();
    _selectedTable = widget.table;
    _loadSlots();
  }

  @override
  void dispose() {
    _specialCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    final slots = await ApiService.getTimeSlots();
    if (mounted) setState(() => _slots = slots);
  }

  Future<void> _checkAvailability() async {
    if (_selectedSlot == null) return;
    setState(() => _checkingAvail = true);

    final data = await ApiService.getAvailability(
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      slotId: _selectedSlot!.id,
      guests: _guestCount,
    );

    if (mounted) {
      setState(() {
        _checkingAvail = false;
        if (data['success'] == true) {
          _availableTables = (data['tables'] as List)
              .map((t) => TableModel.fromJson(t))
              .toList();
        } else {
          _availableTables = [];
        }
      });
    }
  }

  Future<void> _confirmBooking() async {
    final table = _selectedTable ?? widget.table;
    if (table == null || _selectedSlot == null) return;

    setState(() => _loading = true);
    final res = await ApiService.createReservation(
      tableId: table.id,
      slotId: _selectedSlot!.id,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      guests: _guestCount,
      specialRequest: _specialCtrl.text,
      occasion: _occasion,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (res['success'] == true) {
      _showSuccessDialog(res['reservation_code'] ?? '');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'เกิดข้อผิดพลาด',
            style: GoogleFonts.kanit()),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withOpacity(0.1),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.4)),
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: AppColors.success, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              'จองโต๊ะสำเร็จ!',
              style: GoogleFonts.kanit(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('รหัสการจองของคุณ',
                style:
                    GoogleFonts.kanit(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.gold.withOpacity(0.4)),
              ),
              child: Text(
                code,
                style: GoogleFonts.sourceCodePro(
                  color: AppColors.gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // ปิด dialog แล้ว pop กลับ (TablesScreen/HomeScreen จะ refresh เอง)
                Navigator.of(context).pop(); // ปิด dialog
                Navigator.of(context).pop(); // กลับหน้าก่อนหน้า
              },
              child: const Text('กลับหน้าหลัก'),
            ),
          ],
        ),
      ),
    );
  }

  // จำนวน step จริง
  int get _totalSteps => _hasPreselectedTable ? 2 : 3;

  // แปลง logical step เป็น index ของ IndexedStack
  // ถ้ามี table: step 0 = date/slot, step 1 = confirm (index 0, 2)
  // ถ้าไม่มี:   step 0 = date/slot, step 1 = pick table, step 2 = confirm
  int get _stackIndex {
    if (_hasPreselectedTable) {
      return _step == 0 ? 0 : 2;
    }
    return _step;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จองโต๊ะ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _StepIndicator(current: _step, total: _totalSteps),
        ),
      ),
      body: IndexedStack(
        index: _stackIndex,
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
        ],
      ),
    );
  }

  // ─── Step 1: Date, Slot, Guests ───────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ถ้ามี table preselected ให้แสดงข้อมูลโต๊ะ
          if (_hasPreselectedTable) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.table_restaurant_outlined,
                    color: AppColors.gold, size: 20),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'โต๊ะ ${widget.table!.tableNumber}',
                    style: GoogleFonts.kanit(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700),
                  ),
                  Row(children: [
                    ZoneBadge(widget.table!.zone),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.table!.capacity} คน',
                      style: GoogleFonts.kanit(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ]),
                ]),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          Text(
            'เลือกวันและเวลา',
            style: GoogleFonts.kanit(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          // Calendar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _selectedDate,
              selectedDayPredicate: (d) => isSameDay(d, _selectedDate),
              onDaySelected: (sel, _) =>
                  setState(() => _selectedDate = sel),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                    color: AppColors.gold, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.2),
                    shape: BoxShape.circle),
                defaultTextStyle: GoogleFonts.kanit(
                    color: AppColors.textPrimary),
                weekendTextStyle: GoogleFonts.kanit(
                    color: AppColors.textSecondary),
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.kanit(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600),
                leftChevronIcon:
                    const Icon(Icons.chevron_left, color: AppColors.gold),
                rightChevronIcon:
                    const Icon(Icons.chevron_right, color: AppColors.gold),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.kanit(
                    color: AppColors.textSecondary, fontSize: 12),
                weekendStyle: GoogleFonts.kanit(
                    color: AppColors.textHint, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'จำนวนผู้เข้าร่วม',
            style: GoogleFonts.kanit(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(children: [
            IconButton(
              onPressed: _guestCount > 1
                  ? () => setState(() => _guestCount--)
                  : null,
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.gold),
              iconSize: 32,
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$_guestCount คน',
                  style: GoogleFonts.kanit(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            IconButton(
              onPressed: _guestCount < 20
                  ? () => setState(() => _guestCount++)
                  : null,
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.gold),
              iconSize: 32,
            ),
          ]),
          const SizedBox(height: 24),

          Text(
            'เลือกช่วงเวลา',
            style: GoogleFonts.kanit(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_slots.isEmpty)
            const Center(
                child: CircularProgressIndicator(color: AppColors.gold))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _slots.map((slot) {
                final sel = _selectedSlot?.id == slot.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSlot = slot),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.gold : AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              sel ? AppColors.gold : AppColors.border),
                    ),
                    child: Column(children: [
                      Text(
                        slot.slotName,
                        style: GoogleFonts.kanit(
                          color: sel ? AppColors.bg : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        slot.displayTime,
                        style: GoogleFonts.kanit(
                          color: sel
                              ? AppColors.bg.withOpacity(0.7)
                              : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 32),
          GoldButton(
            text: _hasPreselectedTable
                ? 'ถัดไป: ยืนยันการจอง'
                : 'ถัดไป: เลือกโต๊ะ',
            icon: Icons.arrow_forward,
            onTap: _selectedSlot == null
                ? null
                : () {
                    if (_hasPreselectedTable) {
                      // ข้าม step 2 ไปตรง confirm
                      setState(() => _step = 1);
                    } else {
                      setState(() => _step = 1);
                      _checkAvailability();
                    }
                  },
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Pick Table ────────────────────────
  Widget _buildStep2() {
    return Column(
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Row(children: [
            const Icon(Icons.event, color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            Text(
              DateFormat('d MMM yyyy', 'th_TH').format(_selectedDate),
              style: GoogleFonts.kanit(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.access_time, color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            Text(
              _selectedSlot?.displayTime ?? '',
              style: GoogleFonts.kanit(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.people, color: AppColors.gold, size: 16),
            const SizedBox(width: 8),
            Text(
              '$_guestCount คน',
              style: GoogleFonts.kanit(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
          ]),
        ),
        Expanded(
          child: _checkingAvail
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.gold),
                      SizedBox(height: 16),
                      Text('กำลังตรวจสอบโต๊ะว่าง...',
                          style:
                              TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : _availableTables.isEmpty
                  ? const EmptyState(
                      icon: Icons.table_restaurant_outlined,
                      title: 'ไม่มีโต๊ะว่าง',
                      subtitle: 'กรุณาเลือกวันเวลาอื่น',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _availableTables.length,
                      itemBuilder: (ctx, i) {
                        final t = _availableTables[i];
                        final sel = _selectedTable?.id == t.id;
                        final available = t.isAvailable ?? true;
                        return GestureDetector(
                          onTap: available
                              ? () => setState(() => _selectedTable = t)
                              : null,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: sel
                                    ? const Color.fromARGB(255, 203, 206, 27)
                                    : (available
                                        ? AppColors.border
                                        : AppColors.error.withOpacity(0.3)),
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                    Icons.table_restaurant_outlined,
                                    color: AppColors.gold),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'โต๊ะ ${t.tableNumber}',
                                      style: GoogleFonts.kanit(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Row(children: [
                                      ZoneBadge(t.zone),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${t.capacity} คน',
                                        style: GoogleFonts.kanit(
                                            color: AppColors.textHint,
                                            fontSize: 12),
                                      ),
                                    ]),
                                    if (t.description.isNotEmpty)
                                      Text(
                                        t.description,
                                        style: GoogleFonts.kanit(
                                            color: AppColors.textHint,
                                            fontSize: 11),
                                      ),
                                  ],
                                ),
                              ),
                              Column(children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: available
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  available ? 'ว่าง' : 'ไม่ว่าง',
                                  style: GoogleFonts.kanit(
                                    color: available
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontSize: 11,
                                  ),
                                ),
                                if (sel) ...[
                                  const SizedBox(height: 4),
                                  const Icon(Icons.check_circle,
                                      color: AppColors.gold, size: 18),
                                ],
                              ]),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('ย้อนกลับ', style: GoogleFonts.kanit()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedTable == null
                    ? null
                    : () => setState(() => _step = 2),
                child: Text('ถัดไป',
                    style: GoogleFonts.kanit(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ─── Step 3: Confirm ───────────────────────────
  Widget _buildStep3() {
    final table = _selectedTable ?? widget.table;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ยืนยันการจอง',
            style: GoogleFonts.kanit(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          // Summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withOpacity(0.1),
                  AppColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Column(children: [
              _summaryRow('โต๊ะ', 'โต๊ะ ${table?.tableNumber ?? '-'}'),
              const SizedBox(height: 10),
              _summaryRow(
                'วันที่',
                DateFormat('EEEE d MMMM yyyy', 'th_TH').format(_selectedDate),
              ),
              const SizedBox(height: 10),
              _summaryRow(
                'ช่วงเวลา',
                '${_selectedSlot?.slotName} (${_selectedSlot?.displayTime})',
              ),
              const SizedBox(height: 10),
              _summaryRow('จำนวนคน', '$_guestCount คน'),
              const SizedBox(height: 10),
              _summaryRow('โซน', table?.zone.toUpperCase() ?? '-'),
            ]),
          ),
          const SizedBox(height: 24),

          // Occasion
          Text(
            'โอกาสพิเศษ',
            style: GoogleFonts.kanit(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _occasions.entries.map((e) {
              final sel = _occasion == e.key;
              return GestureDetector(
                onTap: () => setState(() => _occasion = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.gold : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? AppColors.gold : AppColors.border),
                  ),
                  child: Text(
                    e.value,
                    style: GoogleFonts.kanit(
                      color: sel ? AppColors.bg : AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Special request
          TextField(
            controller: _specialCtrl,
            maxLines: 3,
            style: GoogleFonts.kanit(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'คำขอพิเศษ (ถ้ามี)',
              hintText:
                  'เช่น แพ้อาหาร, ต้องการดอกไม้, เก้าอี้เด็ก...',
              prefixIcon: Icon(Icons.notes_outlined,
                  color: AppColors.textHint),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 32),

          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(
                  () => _step = _hasPreselectedTable ? 0 : 1,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('ย้อนกลับ', style: GoogleFonts.kanit()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GoldButton(
                text: 'ยืนยันการจอง',
                loading: _loading,
                onTap: _confirmBooking,
                icon: Icons.check_circle_outline,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.kanit(
                  color: AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: GoogleFonts.kanit(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      );
}

// ─── Step Indicator ───────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int current, total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(
          total,
          (i) => Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
              color: i <= current ? AppColors.gold : AppColors.border,
            ),
          ),
        ),
      );
}
