import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/api.dart';

class LeaveScreen extends StatefulWidget {
  final int initialTab;
  const LeaveScreen({super.key, this.initialTab = 0});
  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  Map<String, dynamic>? _balance;
  List _apps = [];
  bool _loading = true;

  // apply form
  String _type = 'Casual Leave (CL)';
  DateTime _from = DateTime.now(), _to = DateTime.now();
  bool _half = false;
  final _reason = TextEditingController();
  bool _submitting = false;

  final _types = const {
    'Casual Leave (CL)': 'CL', 'Sick Leave (SL)': 'SL', 'Paid Leave (PL)': 'PL',
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await Api.leaveList();
    if (mounted) setState(() {
      if (res['ok'] == true) { _apps = res['applications'] ?? []; _balance = res['balance']; }
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_to.isBefore(_from)) { _snack('To date must be after From date'); return; }
    setState(() => _submitting = true);
    final res = await Api.applyLeave({
      'leave_type': _types[_type],
      'from_date': DateFormat('yyyy-MM-dd').format(_from),
      'to_date': DateFormat('yyyy-MM-dd').format(_to),
      'half_day': _half, 'reason': _reason.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res['ok'] == true) {
      _snack('Leave application submitted', ok: true);
      _reason.clear();
      _load();
      _tab.animateTo(1);
    } else {
      _snack(res['error']?.toString() ?? 'Failed');
    }
  }

  void _snack(String m, {bool ok = false}) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: ok ? AppColors.green : AppColors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
        bottom: TabBar(controller: _tab, labelColor: Colors.white, unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white, tabs: const [Tab(text: 'Balance'), Tab(text: 'Applications'), Tab(text: 'Apply')]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [_balanceTab(), _appsTab(), _applyTab()]),
    );
  }

  // ---- Balance ----
  Widget _balanceTab() {
    final b = _balance ?? {};
    return ListView(padding: const EdgeInsets.all(16), children: [
      _balRow('Casual Leave (CL)', b['CL'] ?? 0, Icons.event_note, AppColors.primary),
      _balRow('Paid Leave (PL)', b['PL'] ?? 0, Icons.event_available, AppColors.purple),
      _balRow('Sick Leave (SL)', b['SL'] ?? 0, Icons.healing, AppColors.amber),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFEFF4FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBFD4FE))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Remaining', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('${b['total'] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(width: 4),
            const Text('Days', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    ]);
  }

  Widget _balRow(String t, dynamic v, IconData icon, Color c) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: cardDecoration(),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: c.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: c, size: 21)),
          const SizedBox(width: 13),
          Expanded(child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text))),
          Text('$v Days', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
        ]),
      );

  // ---- Applications ----
  Widget _appsTab() {
    if (_apps.isEmpty) {
      return const Center(child: Text('No leave applications.', style: TextStyle(color: AppColors.text3)));
    }
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: _apps.length, itemBuilder: (_, i) {
      final a = _apps[i];
      final st = (a['status'] ?? '').toString();
      final col = st == 'approved' ? AppColors.green : st == 'rejected' ? AppColors.red : AppColors.amber;
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(a['leave_type'] ?? '', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.text)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: col.withOpacity(.13), borderRadius: BorderRadius.circular(20)),
                child: Text(st.isEmpty ? '' : '${st[0].toUpperCase()}${st.substring(1)}',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: col))),
          ]),
          const SizedBox(height: 6),
          Text('${_d(a['from_date'])}  →  ${_d(a['to_date'])}', style: const TextStyle(fontSize: 13, color: AppColors.text2)),
          const SizedBox(height: 3),
          Text('${a['days']} Day(s)  •  Applied ${a['applied_at'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.text3)),
        ]),
      );
    });
  }

  String _d(String? s) => s == null ? '' : DateFormat('dd MMM yyyy').format(DateTime.parse(s));

  // ---- Apply ----
  Widget _applyTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _lbl('Leave Type *'),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: _type, isExpanded: true,
          items: _types.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
          onChanged: (v) => setState(() => _type = v!),
        )),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl('From Date *'),
          _dateField(_from, (d) => setState(() => _from = d)),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl('To Date *'),
          _dateField(_to, (d) => setState(() => _to = d)),
        ])),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        SizedBox(width: 24, height: 24, child: Checkbox(value: _half, activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _half = v ?? false))),
        const SizedBox(width: 8),
        const Text('Half Day (for a single day)', style: TextStyle(fontSize: 13.5, color: AppColors.text2)),
      ]),
      const SizedBox(height: 14),
      _lbl('Reason'),
      TextField(controller: _reason, maxLines: 3,
          decoration: InputDecoration(hintText: 'Leave reason...', filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)))),
      const SizedBox(height: 18),
      SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: _submitting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
            : const Text('Submit Application', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
      )),
    ]);
  }

  Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 6),
      child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text2)));

  Widget _dateField(DateTime v, ValueChanged<DateTime> onPick) => InkWell(
        onTap: () async {
          final d = await showDatePicker(context: context, initialDate: v, firstDate: DateTime(2020), lastDate: DateTime(2030));
          if (d != null) onPick(d);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(DateFormat('dd MMM yyyy').format(v), style: const TextStyle(fontSize: 14, color: AppColors.text)),
            const Icon(Icons.event, size: 17, color: AppColors.text3),
          ]),
        ),
      );
}
