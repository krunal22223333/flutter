import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';
import 'profile_edit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _p;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Api.profile();
      if (res['ok'] == true) {
        setState(() => _p = res['profile']);
      } else {
        setState(() => _error = res['error']?.toString() ?? 'Failed to load');
      }
    } catch (e) {
      setState(() => _error = 'Network error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final changed = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
              if (changed == true) _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.red)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      _header(),
                      const SizedBox(height: 14),
                      _section('Personal', Icons.person_outline, _p?['personal']),
                      _section('Job', Icons.work_outline, _p?['job']),
                      _section('Bank Details', Icons.account_balance_outlined, _p?['bank']),
                      _section('Leave Balance', Icons.event_available_outlined, _p?['leave']),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
    );
  }

  Widget _header() {
    final name = _p?['name']?.toString() ?? '';
    final desig = _p?['designation']?.toString() ?? '';
    final code = _p?['employee_code']?.toString() ?? '';
    final dept = _p?['department']?.toString() ?? '';
    final photo = _p?['profile_photo']?.toString() ?? '';
    final photoBytes = photo.startsWith('data:') ? _decodeDataUri(photo) : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.headerGrad1, AppColors.headerGrad2],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 32, backgroundColor: Colors.white,
          backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
          child: photoBytes == null
              ? Text(_initials(name),
                  style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800))
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          if (desig.isNotEmpty)
            Text(desig, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text([if (code.isNotEmpty) code, if (dept.isNotEmpty) dept].join('   |   '),
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Uint8List? _decodeDataUri(String uri) {
    try {
      final b64 = uri.contains(',') ? uri.split(',').last : uri;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Widget _section(String title, IconData icon, dynamic rows) {
    final list = (rows as List?) ?? [];
    final visible = list
        .where((r) => (r as List).length >= 2 && '${r[1]}'.trim().isNotEmpty)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 13, 15, 8),
          child: Row(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
          ]),
        ),
        const Divider(height: 1),
        ...visible.map((r) => _row('${(r as List)[0]}', '${r[1]}')),
        const SizedBox(height: 6),
      ]),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 9, 15, 9),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.text3, fontWeight: FontWeight.w600))),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13.5, color: AppColors.text, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
