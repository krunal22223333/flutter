import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({super.key});
  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  List _slips = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final res = await Api.salarySlips();
    if (mounted) setState(() { _slips = res['ok'] == true ? (res['slips'] ?? []) : []; _loading = false; });
  }

  bool _downloading = false;

  Future<void> _openSlip(Map s) async {
    if (_downloading) return;
    final y = s['year'];
    final m = s['month'];
    if (y == null || m == null) { _snack('Slip details missing'); return; }
    setState(() => _downloading = true);
    _snack('Downloading payslip...');
    try {
      final year = y is int ? y : int.tryParse('$y') ?? 0;
      final month = m is int ? m : int.tryParse('$m') ?? 0;
      final bytes = await Api.salarySlipPdf(year, month);
      if (bytes == null) { _snack('Could not download payslip'); return; }
      final dir = await getTemporaryDirectory();
      final safe = (s['label'] ?? 'payslip').toString().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final path = '${dir.path}/Payslip_$safe.pdf';
      await File(path).writeAsBytes(bytes, flush: true);
      final res = await OpenFilex.open(path);
      if (res.type != ResultType.done) { _snack('Cannot open PDF: ${res.message}'); }
    } catch (e) {
      _snack('Error opening payslip');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salary Slip')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text('Available Salary Slips', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text2, letterSpacing: .3))),
              Expanded(child: _slips.isEmpty
                  ? const Center(child: Text('No salary slips available.', style: TextStyle(color: AppColors.text3)))
                  : ListView.builder(padding: const EdgeInsets.fromLTRB(14, 0, 14, 14), itemCount: _slips.length, itemBuilder: (_, i) {
                      final s = _slips[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(15),
                        decoration: cardDecoration(),
                        child: Row(children: [
                          Container(width: 44, height: 44,
                              decoration: BoxDecoration(color: AppColors.green.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.receipt_long, color: AppColors.green, size: 22)),
                          const SizedBox(width: 13),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s['label'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
                            const SizedBox(height: 2),
                            Text('Net: \u20B9 ${s['net_pay'] ?? 0}', style: const TextStyle(fontSize: 13.5, color: AppColors.text2, fontWeight: FontWeight.w600)),
                          ])),
                          TextButton(onPressed: () => _openSlip(s as Map), child: const Text('View', style: TextStyle(fontWeight: FontWeight.w700))),
                        ]),
                      );
                    })),
            ]),
    );
  }
}
