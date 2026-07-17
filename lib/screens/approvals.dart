import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/api.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});
  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  List _leaves = [], _manual = [];
  bool _loading = true;
  final Set<String> _busy = {}; // 'leave-<id>' / 'manual-<id>' currently processing

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await Api.approvals();
    if (mounted) setState(() {
      if (res['ok'] == true) { _leaves = res['leaves'] ?? []; _manual = res['manual'] ?? []; }
      _loading = false;
    });
  }

  String _d(String? s) => s == null ? '' : DateFormat('dd MMM yyyy').format(DateTime.parse(s));
  void _snack(String m, {bool ok = false}) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: ok ? AppColors.green : AppColors.red));

  Future<void> _act(String type, int id, String action, {String note = ''}) async {
    final key = '$type-$id';
    setState(() => _busy.add(key));
    final res = type == 'leave'
        ? await Api.leaveDecision(id, action, note: note)
        : await Api.manualDecision(id, action, note: note);
    if (!mounted) return;
    setState(() => _busy.remove(key));
    if (res['ok'] == true) {
      _snack(action == 'approve' ? 'Approved' : 'Rejected', ok: true);
      _load();
    } else {
      _snack(res['error']?.toString() ?? 'Failed');
    }
  }

  Future<void> _confirmApprove(String type, int id) async {
    final msg = type == 'leave'
        ? 'Approve this leave? Balance will be auto-deducted.'
        : 'Approve this attendance request?';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm Approve'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white),
            child: const Text('Approve')),
        ],
      ),
    );
    if (ok == true) _act(type, id, 'approve');
  }

  Future<void> _confirmReject(String type, int id) async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Reason (optional):', style: TextStyle(fontSize: 13, color: AppColors.text2)),
          const SizedBox(height: 8),
          TextField(controller: ctl, maxLines: 2, decoration: InputDecoration(
            hintText: 'e.g. incorrect times',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            child: const Text('Reject')),
        ],
      ),
    );
    if (ok == true) _act(type, id, 'reject', note: ctl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final total = _leaves.length + _manual.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: total == 0
                  ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.32),
                      Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.fact_check_outlined, size: 64, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 12),
                        Text('No pending approvals', style: TextStyle(color: AppColors.text3, fontSize: 15)),
                      ])),
                    ])
                  : ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(14), children: [
                      Padding(padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Pending Approval ($total)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text2))),
                      ..._leaves.map((l) => _card(
                            type: 'leave', id: (l['id'] as num).toInt(),
                            icon: Icons.event_note, color: AppColors.primary,
                            title: l['employee'] ?? '',
                            sub: '${l['leave_type'] ?? 'Leave'}  \u2022  ${_d(l['from_date'])} \u2192 ${_d(l['to_date'])}  \u2022  ${l['days']} day(s)',
                          )),
                      ..._manual.map((m) => _card(
                            type: 'manual', id: (m['id'] as num).toInt(),
                            icon: Icons.pending_actions, color: AppColors.orange,
                            title: m['employee'] ?? '',
                            sub: 'Manual Attendance  \u2022  ${_d(m['date'])}'
                                '${m['in_time'] != null ? '  \u2022  In ${m['in_time']}' : ''}'
                                '${m['out_time'] != null ? '  Out ${m['out_time']}' : ''}',
                          )),
                    ]),
            ),
    );
  }

  Widget _card({required String type, required int id, required IconData icon, required Color color, required String title, required String sub}) {
    final busy = _busy.contains('$type-$id');
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 3),
            Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
          ])),
        ]),
        const SizedBox(height: 12),
        busy
            ? const Padding(padding: EdgeInsets.symmetric(vertical: 6),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))))
            : Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _confirmReject(type, id),
                  icon: const Icon(Icons.close, size: 17),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.red,
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => _confirmApprove(type, id),
                  icon: const Icon(Icons.check, size: 17),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
                )),
              ]),
      ]),
    );
  }
}
