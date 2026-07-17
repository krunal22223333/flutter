import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _obCur = true, _obNew = true, _obCon = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cur = _current.text;
    final nw = _new.text;
    final cn = _confirm.text;
    if (cur.isEmpty || nw.isEmpty || cn.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    if (nw.length < 4) {
      setState(() => _error = 'New password must be at least 4 characters');
      return;
    }
    if (nw != cn) {
      setState(() => _error = 'New password and confirm do not match');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final res = await Api.changePassword(cur, nw);
      if (res['ok'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password changed successfully'), duration: Duration(seconds: 2)));
        Navigator.pop(context);
      } else {
        setState(() => _error = res['error']?.toString() ?? 'Change failed');
      }
    } catch (e) {
      setState(() => _error = 'Network error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(_current, 'Current Password', _obCur, () => setState(() => _obCur = !_obCur)),
            const SizedBox(height: 16),
            _field(_new, 'New Password', _obNew, () => setState(() => _obNew = !_obNew)),
            const SizedBox(height: 16),
            _field(_confirm, 'Confirm New Password', _obCon, () => setState(() => _obCon = !_obCon)),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!,
                  style: const TextStyle(color: AppColors.red, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Update Password',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(fontSize: 16, color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.text3),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F5F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
      ),
    );
  }
}
