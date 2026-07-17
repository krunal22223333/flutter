import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Central API client for the HCP HRMS employee app.
/// Talks to the Flask JSON API: https://hcperp.in/api/ess/...
class Api {
  static const String baseUrl = 'https://hcperp.in';
  static const String _apiPath = '/api/ess';
  static const String _tokenKey = 'ess_token';

  // ---- token storage ----
  static Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers() async {
    final t = await getToken();
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  // ---- generic calls ----
  static Future<Map<String, dynamic>> _get(String path, [Map<String, String>? q]) async {
    final uri = Uri.parse('$baseUrl$_apiPath$path').replace(queryParameters: q);
    final res = await http.get(uri, headers: await _headers());
    return _decode(res);
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$_apiPath$path');
    final res = await http.post(uri, headers: await _headers(), body: jsonEncode(body));
    return _decode(res);
  }

  static Map<String, dynamic> _decode(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data;
    } catch (_) {
      return {'ok': false, 'error': 'Server error (${res.statusCode})'};
    }
  }

  // ---- endpoints ----
  static Future<Map<String, dynamic>> login(String username, String password) =>
      _post('/login', {'username': username, 'password': password});

  static Future<Map<String, dynamic>> dashboard() => _get('/dashboard');

  static Future<Map<String, dynamic>> attendance(String month) =>
      _get('/attendance', {'month': month});

  static Future<Map<String, dynamic>> submitAttendance(String date, String inTime, String outTime) =>
      _post('/attendance/request', {'date': date, 'in_time': inTime, 'out_time': outTime});

  static Future<Map<String, dynamic>> leaveBalance() => _get('/leave/balance');
  static Future<Map<String, dynamic>> leaveList() => _get('/leave/list');
  static Future<Map<String, dynamic>> applyLeave(Map<String, dynamic> body) => _post('/leave/apply', body);

  static Future<Map<String, dynamic>> salarySlips() => _get('/salary/slips');

  /// Payslip PDF bytes (auth header sent). null = failed.
  static Future<List<int>?> salarySlipPdf(int year, int month) async {
    final uri = Uri.parse('$baseUrl$_apiPath/salary/slip/$year/$month');
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) return res.bodyBytes;
    return null;
  }
  static Future<Map<String, dynamic>> holidays() => _get('/holidays');
  static Future<Map<String, dynamic>> team() => _get('/team');
  static Future<Map<String, dynamic>> profile() => _get('/profile');
  static Future<Map<String, dynamic>> profileEditData() => _get('/profile/edit');
  static Future<Map<String, dynamic>> profileSave(Map<String, dynamic> body) => _post('/profile/save', body);
  static Future<Map<String, dynamic>> changePassword(String current, String newPass) =>
      _post('/change-password', {'current_password': current, 'new_password': newPass});
  static Future<Map<String, dynamic>> form16() => _get('/form16');
  static Future<Map<String, dynamic>> approvals() => _get('/approvals');

  static Future<Map<String, dynamic>> leaveDecision(int id, String action, {String note = ''}) =>
      _post('/leave/$id/decision', {'action': action, 'note': note});
  static Future<Map<String, dynamic>> manualDecision(int id, String action, {String note = ''}) =>
      _post('/manual/$id/decision', {'action': action, 'note': note});

  static Future<Map<String, dynamic>> registerDevice(String token, String platform) =>
      _post('/register-device', {'token': token, 'platform': platform});

  static Future<Map<String, dynamic>> celebrations() => _get('/celebrations');
  static Future<Map<String, dynamic>> sendWish(int empId, String wishType, String wishText) =>
      _post('/send-wish', {'emp_id': empId, 'wish_type': wishType, 'wish_text': wishText});

  /// Full URL for a Form 16 PDF download (open in browser / downloader).
  static String form16DownloadUrl(int id) => '$baseUrl$_apiPath/form16/$id/download';
}
