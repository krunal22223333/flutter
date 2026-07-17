import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});
  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List _members = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final res = await Api.team();
    if (mounted) setState(() { _members = res['ok'] == true ? (res['members'] ?? []) : []; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Members')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.groups_outlined, size: 64, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 12),
                  Text('No team members found.', style: TextStyle(color: AppColors.text3, fontSize: 15)),
                ]))
              : ListView.builder(padding: const EdgeInsets.all(14), itemCount: _members.length, itemBuilder: (_, i) {
                  final m = _members[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
                    decoration: cardDecoration(),
                    child: Row(children: [
                      CircleAvatar(radius: 24, backgroundColor: AppColors.primary.withOpacity(.12),
                          child: const Icon(Icons.person, color: AppColors.primary)),
                      const SizedBox(width: 13),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
                        const SizedBox(height: 2),
                        Text('${m['employee_code'] ?? ''}  •  ${m['department'] ?? ''}', style: const TextStyle(fontSize: 12.5, color: AppColors.text3)),
                        if ((m['designation'] ?? '').toString().isNotEmpty)
                          Text(m['designation'], style: const TextStyle(fontSize: 12.5, color: AppColors.text2)),
                      ])),
                    ]),
                  );
                }),
    );
  }
}
