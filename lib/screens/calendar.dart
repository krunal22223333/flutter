import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/api.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, Map<String, dynamic>> _byDate = {};
  bool _loading = true;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _selected = null; });
    final res = await Api.attendance(DateFormat('yyyy-MM').format(_month));
    final map = <String, Map<String, dynamic>>{};
    if (res['ok'] == true) {
      for (final d in (res['days'] as List)) {
        map[d['date']] = Map<String, dynamic>.from(d);
      }
    }
    if (mounted) setState(() { _byDate = map; _loading = false; });
  }

  void _shift(int m) { setState(() => _month = DateTime(_month.year, _month.month + m)); _load(); }

  Color _statusColor(String? s) {
    switch (s) {
      case 'Present': case 'WOP': return AppColors.green;
      case 'Absent': return AppColors.red;
      case 'Half Day': return AppColors.amber;
      case 'MIS-PUNCH': return AppColors.primary;
      case 'Holiday': return AppColors.purple;
      default: return AppColors.text3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startWeekday = first.weekday % 7; // Sun=0
    final cells = <Widget>[];
    for (int i = 0; i < startWeekday; i++) cells.add(const SizedBox());
    for (int d = 1; d <= daysInMonth; d++) {
      final key = DateFormat('yyyy-MM-dd').format(DateTime(_month.year, _month.month, d));
      final rec = _byDate[key];
      final col = _statusColor(rec?['status']);
      final sel = _selected == key;
      cells.add(InkWell(
        onTap: rec == null ? null : () => setState(() => _selected = key),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: sel ? AppColors.primary.withOpacity(.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: sel ? Border.all(color: AppColors.primary) : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$d', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600,
                color: (DateTime(_month.year, _month.month, d).weekday == 7) ? AppColors.red : AppColors.text)),
            const SizedBox(height: 3),
            Container(width: 6, height: 6, decoration: BoxDecoration(color: rec == null ? Colors.transparent : col, shape: BoxShape.circle)),
          ]),
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Calendar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(14), children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left, color: AppColors.primary)),
                Text(DateFormat('MMMM yyyy').format(_month), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right, color: AppColors.primary)),
              ]),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: cardDecoration(),
                child: Column(children: [
                  Row(children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((d) => Expanded(
                      child: Center(child: Text(d, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
                          color: d == 'SUN' ? AppColors.red : AppColors.text3))))).toList()),
                  const SizedBox(height: 6),
                  GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: .82, children: cells),
                ]),
              ),
              const SizedBox(height: 10),
              // legend
              Wrap(spacing: 12, runSpacing: 6, children: [
                _leg('Present', AppColors.green), _leg('Absent', AppColors.red), _leg('Half Day', AppColors.amber),
                _leg('Mis-Punch', AppColors.primary), _leg('Holiday', AppColors.purple),
              ]),
              const SizedBox(height: 14),
              // detail
              if (_selected != null && _byDate[_selected] != null) _detail(_byDate[_selected]!),
            ]),
    );
  }

  Widget _leg(String t, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(t, style: const TextStyle(fontSize: 11.5, color: AppColors.text2)),
      ]);

  Widget _detail(Map<String, dynamic> r) {
    final dt = DateTime.parse(r['date']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(DateFormat('dd MMM yyyy').format(dt), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
          Text(DateFormat('EEE').format(dt), style: const TextStyle(fontSize: 13, color: AppColors.text3)),
        ]),
        const Divider(height: 20),
        _row('In-Time', r['in_time'] ?? '--', AppColors.green),
        _row('Out-Time', r['out_time'] ?? '--', AppColors.green),
        _row('Total Hours', '${r['total_hours'] ?? 0}', AppColors.text),
        _row('Status', r['status'] ?? '-', _statusColor(r['status'])),
      ]),
    );
  }

  Widget _row(String k, String v, Color c) => Padding(padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(k, style: const TextStyle(fontSize: 13.5, color: AppColors.text2)),
        Text(v, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c)),
      ]));
}
