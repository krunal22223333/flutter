import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/api.dart';
import 'calendar.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});
  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, dynamic>? _summary;
  List _days = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await Api.attendance(DateFormat('yyyy-MM').format(_month));
    if (mounted) setState(() {
      if (res['ok'] == true) { _summary = res['summary']; _days = res['days'] ?? []; }
      else { _summary = null; _days = []; }
      _loading = false;
    });
  }

  void _shift(int m) { setState(() => _month = DateTime(_month.year, _month.month + m)); _load(); }

  Color _statusColor(String? s) {
    switch (s) {
      case 'Present': case 'WOP': case 'HLP': return AppColors.green;
      case 'Absent': case 'LOP': return AppColors.red;
      case 'Half Day': return AppColors.amber;
      case 'MIS-PUNCH': return AppColors.primary;
      case 'Holiday': return AppColors.purple;
      case 'On Leave': case 'Leave': case 'CL': case 'SL': case 'PL': return AppColors.teal;
      default: return AppColors.text3;
    }
  }

  String _fmtTod(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  void _snack(String m, {bool ok = false}) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: ok ? AppColors.green : AppColors.red));

  // ---- Mark attendance form (bottom sheet) ----
  void _openMarkSheet() {
    final dateCtl = TextEditingController(text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
    TimeOfDay? tIn, tOut;
    bool submitting = false;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        Widget field(String v, IconData ic, VoidCallback tap) => InkWell(onTap: tap, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(color: const Color(0xFFF3F5F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: Row(children: [Expanded(child: Text(v, style: const TextStyle(fontSize: 14.5, color: AppColors.text))), Icon(ic, size: 18, color: AppColors.text3)])));
        Widget lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text2)));
        return Padding(
          padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [Icon(Icons.edit_note, color: AppColors.primary, size: 22), SizedBox(width: 8),
              Text('Mark My Attendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text))]),
            const SizedBox(height: 18),
            lbl('Date'),
            field(dateCtl.text, Icons.event, () async {
              final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
              if (d != null) setSheet(() => dateCtl.text = DateFormat('dd-MM-yyyy').format(d));
            }),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [lbl('In-Time'),
                field(tIn == null ? '--:--' : _fmtTod(tIn!), Icons.access_time, () async {
                  final t = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 10, minute: 0));
                  if (t != null) setSheet(() => tIn = t);
                })])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [lbl('Out-Time'),
                field(tOut == null ? '--:--' : _fmtTod(tOut!), Icons.access_time, () async {
                  final t = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 19, minute: 0));
                  if (t != null) setSheet(() => tOut = t);
                })])),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
              onPressed: submitting ? null : () async {
                if (tIn == null || tOut == null) { _snack('Please select In and Out time'); return; }
                setSheet(() => submitting = true);
                final d = DateFormat('yyyy-MM-dd').format(DateFormat('dd-MM-yyyy').parse(dateCtl.text));
                final res = await Api.submitAttendance(d, _fmtTod(tIn!), _fmtTod(tOut!));
                setSheet(() => submitting = false);
                if (res['ok'] == true) { Navigator.pop(ctx); _snack('Attendance request submitted', ok: true); _load(); }
                else { _snack(res['error']?.toString() ?? 'Failed'); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Text('Submit Request', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
            )),
          ]),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _summary ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance'), actions: [
        IconButton(icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()))),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(14), children: [
                // month switcher
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left, color: AppColors.primary)),
                  Text(DateFormat('MMMM yyyy').format(_month), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text)),
                  IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right, color: AppColors.primary)),
                ]),
                const SizedBox(height: 6),
                // stats
                GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2, children: [
                    _stat('${s['present'] ?? 0}', 'Present', AppColors.green),
                    _stat('${s['half_day'] ?? 0}', 'Half Day', AppColors.primary),
                    _stat('${s['absent'] ?? 0}', 'LOP', AppColors.red),
                    _stat('${s['mis_punch'] ?? 0}', 'Mis-Punch', AppColors.orange),
                    _stat('${s['holiday'] ?? 0}', 'Holiday', AppColors.purple),
                  ]),
                const SizedBox(height: 16),
                // Mark My Attendance button
                SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
                  onPressed: _openMarkSheet,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Mark My Attendance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                )),
                const SizedBox(height: 18),
                // Attendance list
                const Padding(padding: EdgeInsets.only(bottom: 8, left: 2),
                    child: Text('Attendance Records', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.text2))),
                if (_days.isEmpty)
                  Container(padding: const EdgeInsets.all(24), decoration: cardDecoration(),
                      child: const Center(child: Text('No attendance records this month.', style: TextStyle(color: AppColors.text3))))
                else
                  ..._days.map((d) => _dayRow(d)),
              ]),
            ),
    );
  }

  Widget _dayRow(Map d) {
    final dt = DateTime.parse(d['date']);
    final col = _statusColor(d['status']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(13),
      decoration: cardDecoration(),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(DateFormat('dd').format(dt), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text)),
          Text(DateFormat('EEE').format(dt), style: const TextStyle(fontSize: 11, color: AppColors.text3)),
        ]),
        Container(width: 1, height: 34, margin: const EdgeInsets.symmetric(horizontal: 13), color: AppColors.border),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.login, size: 13, color: AppColors.green), const SizedBox(width: 4),
            Text(d['in_time'] ?? '--:--', style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w600)),
            const SizedBox(width: 14),
            const Icon(Icons.logout, size: 13, color: AppColors.red), const SizedBox(width: 4),
            Text(d['out_time'] ?? '--:--', style: const TextStyle(fontSize: 13, color: AppColors.text, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 3),
          Text('${d['total_hours'] ?? 0} hrs', style: const TextStyle(fontSize: 11.5, color: AppColors.text3)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: col.withOpacity(.13), borderRadius: BorderRadius.circular(20)),
            child: Text(d['status'] ?? '-', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: col))),
      ]),
    );
  }

  Widget _stat(String n, String l, Color c) => Container(
        decoration: cardDecoration(),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(n, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c)),
          Text(l, style: const TextStyle(fontSize: 12.5, color: AppColors.text2, fontWeight: FontWeight.w600)),
        ])),
      );
}
