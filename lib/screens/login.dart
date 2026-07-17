import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';
import '../services/notifications.dart';
import 'home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final p = await SharedPreferences.getInstance();
    final r = p.getBool('remember_me') ?? true;
    if (!mounted) return;
    setState(() {
      _remember = r;
      if (r) {
        _user.text = p.getString('saved_user') ?? '';
        _pass.text = p.getString('saved_pass') ?? '';
      }
    });
  }

  Future<void> _signIn() async {
    if (_user.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Please enter User ID and Password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Api.login(_user.text.trim(), _pass.text);
      if (res['ok'] == true && res['token'] != null) {
        await Api.saveToken(res['token']);
        final p = await SharedPreferences.getInstance();
        if (_remember) {
          await p.setBool('remember_me', true);
          await p.setString('saved_user', _user.text.trim());
          await p.setString('saved_pass', _pass.text);
        } else {
          await p.setBool('remember_me', false);
          await p.remove('saved_user');
          await p.remove('saved_pass');
        }
        NotificationService.registerToken();
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() => _error = res['error']?.toString() ?? 'Login failed');
      }
    } catch (e) {
      setState(() => _error = 'Network error. Check connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Logo
              Image.asset('assets/logo.png', height: 76),
              const SizedBox(height: 34),
              Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text)),
                    const SizedBox(height: 4),
                    const Text('Sign in to your account', style: TextStyle(fontSize: 15, color: AppColors.text2)),
                    const SizedBox(height: 26),
                    _label('User ID or Email'),
                    _field(_user, hint: 'HCP1015', icon: Icons.person_outline),
                    const SizedBox(height: 18),
                    _label('Password'),
                    _field(_pass, hint: '••••••••', icon: Icons.lock_outline, obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppColors.text3),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        )),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          SizedBox(width: 22, height: 22, child: Checkbox(value: _remember, activeColor: AppColors.primary,
                              onChanged: (v) => setState(() => _remember = v ?? true))),
                          const SizedBox(width: 8),
                          const Text('Remember me', style: TextStyle(fontSize: 14, color: AppColors.text2)),
                        ]),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
                        child: Row(children: [
                          const Icon(Icons.error_outline, size: 17, color: AppColors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.red, fontWeight: FontWeight.w600))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity, height: 54,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signIn,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _loading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.login, size: 20), SizedBox(width: 10),
                                Text('Sign In', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                              ]),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(children: const [
                            Icon(Icons.verified_user_outlined, size: 15, color: AppColors.text3),
                            SizedBox(width: 6),
                            Text('SECURED ACCESS', style: TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w700, letterSpacing: .5)),
                          ])),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ]),
                    const SizedBox(height: 12),
                    Center(child: Row(mainAxisSize: MainAxisSize.min, children: const [
                      Icon(Icons.lock_outline, size: 15, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('256-bit SSL  •  Role-based control', style: TextStyle(fontSize: 13, color: AppColors.text2, fontWeight: FontWeight.w600)),
                    ])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(t, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.text2)));

  Widget _field(TextEditingController c, {required String hint, required IconData icon, bool obscure = false, Widget? suffix}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(fontSize: 16, color: AppColors.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.text3),
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFEFF3FB), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF3F5F9),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
      ),
    );
  }
}
