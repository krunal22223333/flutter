import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';

class Form16Screen extends StatefulWidget {
  const Form16Screen({super.key});
  @override
  State<Form16Screen> createState() => _Form16ScreenState();
}

class _Form16ScreenState extends State<Form16Screen> {
  List _forms = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final res = await Api.form16();
    if (mounted) setState(() { _forms = res['ok'] == true ? (res['forms'] ?? []) : []; _loading = false; });
  }

  void _webNote() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form 16 PDF available on the web portal'), duration: Duration(seconds: 2)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Form 16')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _forms.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.description_outlined, size: 60, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 12),
                  Text('No Form 16 available yet.', style: TextStyle(color: AppColors.text3, fontSize: 15)),
                ]))
              : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _forms.length, itemBuilder: (_, i) {
                  final f = _forms[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16),
                    decoration: cardDecoration(),
                    child: Column(children: [
                      Row(children: [
                        Container(width: 44, height: 44,
                            decoration: BoxDecoration(color: AppColors.purple.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.description, color: AppColors.purple, size: 22)),
                        const SizedBox(width: 13),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Financial Year', style: TextStyle(fontSize: 11.5, color: AppColors.text3, fontWeight: FontWeight.w600)),
                          Text(f['financial_year'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          const Text('Uploaded On', style: TextStyle(fontSize: 11.5, color: AppColors.text3, fontWeight: FontWeight.w600)),
                          Text(f['uploaded_at'] ?? '', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text2)),
                        ]),
                      ]),
                      const SizedBox(height: 14),
                      SizedBox(width: double.infinity, height: 46, child: ElevatedButton.icon(
                        onPressed: _webNote,
                        icon: const Icon(Icons.download, size: 19),
                        label: const Text('Download', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      )),
                    ]),
                  );
                }),
    );
  }
}
