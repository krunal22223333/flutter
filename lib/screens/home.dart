import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme.dart';
import '../services/api.dart';
import 'login.dart';
import 'attendance.dart';
import 'calendar.dart';
import 'leave.dart';
import 'team.dart';
import 'salary.dart';
import 'holidays.dart';
import 'form16.dart';
import 'change_password.dart';
import 'approvals.dart';
import 'celebrations.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;
  bool _celebChecked = false;
  Set<String> _modules = {};
  bool _modulesLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Api.dashboard();
      if (res['ok'] == true) {
        setState(() {
          _profile = res['profile'];
          _summary = res['summary'];
          if (res['modules'] is List) {
            _modules = Set<String>.from((res['modules'] as List).map((e) => e.toString()));
            _modulesLoaded = true;
          }
        });
        _checkCelebrations();
      } else {
        if (res['error'] == 'Unauthorized') { _goLogin(); return; }
        setState(() => _error = res['error']?.toString() ?? 'Failed to load');
      }
    } catch (e) {
      setState(() => _error = 'Network error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _checkCelebrations() async {
    if (_celebChecked) return;
    _celebChecked = true;
    try {
      final res = await Api.celebrations();
      if (res['ok'] == true) {
        final all = (res['celebrations'] as List?) ?? [];
        final myWishes = (res['my_wishes'] as List?) ?? [];
        final todayList = all.where((c) => (c as Map)['today'] == true).toList();
        final othersToday = todayList.where((c) => (c as Map)['is_self'] != true).toList();
        // Popup sirf tab jab kisi ko wish karna baaki ho; sabko wish ho chuka to popup nahi.
        final pending = othersToday.where((c) => (c as Map)['already_wished'] != true).toList();
        if (pending.isNotEmpty && mounted) {
          showCelebrationsDialog(context, todayList, myWishes: myWishes);
        }
      }
    } catch (_) {}
  }

  void _goLogin() async {
    await Api.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // 3-dot (More) bottom-sheet menu - holds Logout (moved here from the header).
  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_reset, color: AppColors.primary),
              title: const Text('Change Password',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.primary),
              title: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
              onTap: () {
                Navigator.pop(ctx);
                _goLogin();
              },
            ),
          ],
        ),
      ),
    );
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Uint8List? _decodeDataUri(String uri) {
    try {
      final b64 = uri.contains(',') ? uri.split(',').last : uri;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  void _soon(String name) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('$name — coming in next update'), duration: const Duration(seconds: 1)));

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) => _load());
  }

  // ESS module toggle: key enabled hai ya nahi. Jab tak modules load na ho
  // (ya API purani ho aur field na bheje) tab tak sab dikhao (backward-safe).
  bool _en(String key) => !_modulesLoaded || _modules.contains(key);

  // Bottom nav entries - sirf enabled tabs. Home + More hamesha rehte hain.
  List<Map<String, dynamic>> _navEntries() {
    final list = <Map<String, dynamic>>[
      {'icon': Icons.home_outlined, 'label': 'Home'},
    ];
    if (_en('my_attendance')) list.add({'icon': Icons.calendar_month_outlined, 'label': 'Attendance', 'screen': const AttendanceScreen()});
    if (_en('leave_apply') || _en('leave_balance')) list.add({'icon': Icons.event_note_outlined, 'label': 'Leave', 'screen': const LeaveScreen()});
    list.add({'icon': Icons.person_outline, 'label': 'Profile', 'screen': const ProfileScreen()});
    list.add({'icon': Icons.more_vert, 'label': 'More', 'menu': true});
    return list;
  }

  void _showQr(String code, String name) {
    showDialog(context: context, builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
          const SizedBox(height: 3),
          Text(code, style: const TextStyle(fontSize: 13, color: AppColors.text3, fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          QrImageView(data: code, size: 220),
          const SizedBox(height: 10),
          const Text('Scan for identification', style: TextStyle(fontSize: 12, color: AppColors.text3)),
        ]),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name']?.toString() ?? 'Employee';
    final desig = _profile?['designation']?.toString() ?? '';
    final code = _profile?['employee_code']?.toString() ?? '';
    final dept = _profile?['department']?.toString() ?? '';
    final photo = _profile?['profile_photo']?.toString() ?? '';
    final photoBytes = photo.startsWith('data:') ? _decodeDataUri(photo) : null;
    final nav = _navEntries();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ---- Header ----
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.headerGrad1, AppColors.headerGrad2],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SizedBox(width: 1),
                                Row(children: [
                                  IconButton(onPressed: () => _soon('Notifications'),
                                      icon: const Icon(Icons.notifications_none, color: Colors.white)),
                                ]),
                              ],
                            ),
                            Text(_greeting, style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                              child: Row(children: [
                                CircleAvatar(radius: 26, backgroundColor: AppColors.primary.withOpacity(.12),
                                    backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
                                    child: photoBytes == null ? const Icon(Icons.person, color: AppColors.primary, size: 30) : null),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                                    if (desig.isNotEmpty) Text(desig, style: const TextStyle(fontSize: 13, color: AppColors.text2)),
                                    const SizedBox(height: 4),
                                    Text([if (code.isNotEmpty) code, if (dept.isNotEmpty) dept].join('   |   '),
                                        style: const TextStyle(fontSize: 12, color: AppColors.text3, fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                                if (code.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => _showQr(code, name),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                                      child: QrImageView(data: code, size: 52, padding: EdgeInsets.zero),
                                    ),
                                  ),
                                ],
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(padding: const EdgeInsets.all(16),
                        child: Text(_error!, style: const TextStyle(color: AppColors.red))),
                  // ---- Quick actions ----
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
                    child: GridView.count(
                      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.7,
                      children: [
                        if (_en('my_attendance')) _card('My Attendance', 'View attendance', Icons.calendar_month, AppColors.primary, () => _open(const AttendanceScreen())),
                        if (_en('my_team')) _card('My Team', 'View team members', Icons.groups_outlined, AppColors.teal, () => _open(const TeamScreen())),
                        if (_en('leave_apply')) _card('Leave Apply', 'Apply for leave', Icons.event_available, AppColors.green, () => _open(const LeaveScreen(initialTab: 2))),
                        if (_en('leave_balance')) _card('Leave Balance', 'Check balance', Icons.pie_chart_outline, AppColors.purple, () => _open(const LeaveScreen(initialTab: 0))),
                        if (_en('salary_slip')) _card('Salary Slip', 'View salary slips', Icons.receipt_long, AppColors.green, () => _open(const SalaryScreen())),
                        if (_en('approvals')) _card('Approvals', 'Pending approvals', Icons.fact_check_outlined, AppColors.orange, () => _open(const ApprovalsScreen())),
                        if (_en('holiday_list')) _card('Holiday List', 'View holidays', Icons.beach_access_outlined, AppColors.primary, () => _open(const HolidaysScreen())),
                        if (_en('form16')) _card('My Forms', 'Form 16 & docs', Icons.description_outlined, AppColors.purple, () => _open(const Form16Screen())),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.text3,
        onTap: (i) {
          final entry = nav[i];
          if (entry['menu'] == true) { _showMoreMenu(); }
          else if (entry['screen'] != null) { _open(entry['screen'] as Widget); }
          else if (i != 0) { _soon(entry['label'] as String); }
        },
        items: [
          for (final e in nav)
            BottomNavigationBarItem(icon: Icon(e['icon'] as IconData), label: e['label'] as String),
        ],
      ),
    );
  }

  Widget _card(String title, String sub, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}
