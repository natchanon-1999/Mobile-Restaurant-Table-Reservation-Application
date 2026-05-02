// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../tables/tables_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../admin/admin_home_screen.dart';

// Global key เพื่อให้หน้าลูกเรียก switchTab ได้
final homeScreenKey = GlobalKey<HomeScreenState>();

class HomeScreen extends StatefulWidget {
  HomeScreen() : super(key: homeScreenKey);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void switchTab(int index) {
    if (mounted) setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdmin;

    final pages = isAdmin
        ? [
            const AdminHomeScreen(),
            const TablesScreen(adminMode: true),
            const AllReservationsScreen(),
            const ProfileScreen(),
          ]
        : [
            const CustomerHomeTab(),
            const TablesScreen(),
            const HistoryScreen(),
            const ProfileScreen(),
          ];

    final items = isAdmin
        ? const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'แดชบอร์ด'),
            BottomNavigationBarItem(
                icon: Icon(Icons.table_restaurant_outlined),
                activeIcon: Icon(Icons.table_restaurant),
                label: 'โต๊ะ'),
            BottomNavigationBarItem(
                icon: Icon(Icons.event_note_outlined),
                activeIcon: Icon(Icons.event_note),
                label: 'การจอง'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'โปรไฟล์'),
          ]
        : const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'หน้าแรก'),
            BottomNavigationBarItem(
                icon: Icon(Icons.table_restaurant_outlined),
                activeIcon: Icon(Icons.table_restaurant),
                label: 'จองโต๊ะ'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'ประวัติ'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'โปรไฟล์'),
          ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: items,
        ),
      ),
    );
  }
}

// ─── Customer Home Tab ────────────────────────────
class CustomerHomeTab extends StatelessWidget {
  const CustomerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.bg,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A1200), AppColors.bg],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          AppColors.gold.withOpacity(0.18),
                          Colors.transparent,
                        ]),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 70, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'สวัสดี, ${user?.name.split(' ').first ?? 'คุณลูกค้า'} 👋',
                          style: GoogleFonts.kanit(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'จองโต๊ะ\nสำหรับค่ำคืนพิเศษ',
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            title: Text(
              'Mobile Restaurant Table Reservation Application',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _quickActionsGrid(context),
                  const SizedBox(height: 32),
                  Text(
                    'โซนนั่งทานอาหาร',
                    style: GoogleFonts.kanit(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _zoneCards(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionsGrid(BuildContext context) {
    final actions = [
      {
        'icon': Icons.add_circle_outline,
        'label': 'จองโต๊ะ',
        'color': AppColors.gold,
        'index': 1
      },
      {
        'icon': Icons.history_outlined,
        'label': 'ประวัติจอง',
        'color': AppColors.info,
        'index': 2
      },
      {
        'icon': Icons.search_outlined,
        'label': 'ค้นหา',
        'color': AppColors.success,
        'index': 2
      },
      {
        'icon': Icons.person_outline,
        'label': 'โปรไฟล์',
        'color': AppColors.warning,
        'index': 3
      },
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      children: actions.map((a) {
        final color = a['color'] as Color;
        return GestureDetector(
          onTap: () {
            // ใช้ global key แทน findAncestorStateOfType
            homeScreenKey.currentState?.switchTab(a['index'] as int);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(a['icon'] as IconData, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                a['label'] as String,
                style: GoogleFonts.kanit(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _zoneCards(BuildContext context) {
    final zones = [
      {
        'name': 'Indoor',
        'zone': 'indoor',
        'desc': 'บรรยากาศอบอุ่น',
        'icon': Icons.weekend_outlined,
        'color': AppColors.indoor
      },
      {
        'name': 'Outdoor',
        'zone': 'outdoor',
        'desc': 'วิวสวนสวย',
        'icon': Icons.park_outlined,
        'color': AppColors.outdoor
      },
      {
        'name': 'VIP',
        'zone': 'vip',
        'desc': 'บริการพิเศษ',
        'icon': Icons.star_outline,
        'color': AppColors.vip
      },
      {
        'name': 'Rooftop',
        'zone': 'rooftop',
        'desc': 'วิว 360 องศา',
        'icon': Icons.roofing_outlined,
        'color': AppColors.rooftop
      },
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: zones.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final z = zones[i];
          final color = z['color'] as Color;
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TablesScreen(filterZone: z['zone'] as String),
                ),
              );
            },
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(z['icon'] as IconData, color: color, size: 28),
                  const Spacer(),
                  Text(
                    z['name'] as String,
                    style: GoogleFonts.kanit(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    z['desc'] as String,
                    style: GoogleFonts.kanit(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Admin All Reservations wrapper ───────────────
class AllReservationsScreen extends StatelessWidget {
  const AllReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistoryScreen(adminMode: true);
  }
}
