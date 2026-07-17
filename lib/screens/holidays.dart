import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../services/api.dart';

class HolidaysScreen extends StatefulWidget {
  const HolidaysScreen({super.key});
  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  List _holidays = [];
  bool _loading = true;
  int _year = DateTime.now().year;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final res = await Api.holidays();
    if (mounted) setState(() {
      if (res['ok'] == true) { _holidays = res['holidays'] ?? []; _year = res['year'] ?? _year; }
      _loading = false;
    });
  }

  final _mColors = const [Color(0xFFDBEAFE), Color(0xFFFEE2E2), Color(0xFFDCFCE7), Color(0xFFFFEDD5), Color(0xFFEDE9FE), Color(0xFFFEF3C7)];
  final _mText = const [Color(0xFF2563EB), Color(0xFFDC2626), Color(0xFF16A34A), Color(0xFFEA580C), Color(0xFF7C3AED), Color(0xFFCA8A04)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Holiday List')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Container(width: double.infinity, padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Text('$_year', textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text))),
              Expanded(child: _holidays.isEmpty
                  ? const Center(child: Text('No holidays found.', style: TextStyle(color: AppColors.text3)))
                  : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _holidays.length, itemBuilder: (_, i) {
                      final h = _holidays[i];
                      final dt = DateTime.parse(h['date']);
                      final ci = dt.month % 6;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(13),
                        decoration: cardDecoration(),
                        child: Row(children: [
                          Container(width: 52, height: 52,
                              decoration: BoxDecoration(color: _mColors[ci], borderRadius: BorderRadius.circular(10)),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(DateFormat('dd').format(dt), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _mText[ci])),
                                Text(DateFormat('MMM').format(dt).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _mText[ci])),
                              ])),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(h['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                            const SizedBox(height: 2),
                            Text('${h['type'] ?? ''}  •  ${h['applies_to'] ?? ''}', style: const TextStyle(fontSize: 12.5, color: AppColors.text3)),
                          ])),
                        ]),
                      );
                    })),
            ]),
    );
  }
}
