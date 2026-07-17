import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'photo_crop.dart';

// Field: [key, label, type, (optionsKey)]
// type = text | num | multiline | select | date | bool
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, String> _vals = {};
  final Map<String, String> _readonly = {};
  String _photo = '';
  List<Map<String, dynamic>> _docs = [];
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic> _options = {};

  static const List<Map<String, dynamic>> _sections = [
    {
      'title': 'Basic Info',
      'icon': Icons.person_outline,
      'fields': [
        ['full_name', 'Full Name', 'text'],
        ['email', 'Email', 'text'],
        ['first_name', 'First Name', 'text'],
        ['middle_name', 'Middle Name', 'text'],
        ['last_name', 'Last Name', 'text'],
        ['mobile', 'Mobile', 'text'],
        ['gender', 'Gender', 'select', 'gender'],
        ['date_of_birth', 'Date of Birth', 'date'],
        ['blood_group', 'Blood Group', 'select', 'blood_group'],
        ['marital_status', 'Marital Status', 'select', 'marital_status'],
        ['marriage_anniversary', 'Marriage Anniversary', 'date'],
        ['status', 'Status', 'select', 'status'],
        ['employee_type', 'Employee Type', 'select', 'employee_type'],
        ['father_name', "Father's Name", 'text'],
        ['mother_name', "Mother's Name", 'text'],
        ['alternate_mobile', 'Alternate Mobile', 'text'],
        ['personal_email', 'Personal Email', 'text'],
        ['address', 'Current Address', 'multiline'],
        ['city', 'City', 'text'],
        ['state', 'State', 'text'],
        ['country', 'Country', 'text'],
        ['zip_code', 'ZIP / Pin Code', 'text'],
        ['same_as_current_addr', 'Permanent same as Current', 'bool'],
        ['permanent_address', 'Permanent Address', 'multiline'],
        ['permanent_city', 'Permanent City', 'text'],
        ['permanent_state', 'Permanent State', 'text'],
        ['permanent_country', 'Permanent Country', 'text'],
        ['permanent_zip', 'Permanent ZIP', 'text'],
      ],
    },
    {
      'title': 'Professional',
      'icon': Icons.work_outline,
      'fields': [
        ['department', 'Department', 'select', 'department'],
        ['designation', 'Designation', 'select', 'designation'],
        ['pay_grade', 'Pay Grade', 'select', 'pay_grade'],
        ['grade_level', 'Grade / Level', 'text'],
        ['date_of_joining', 'Date of Joining', 'date'],
        ['confirmation_date', 'Confirmation Date', 'date'],
        ['location', 'Location / Branch', 'select', 'location'],
        ['shift', 'Shift', 'select', 'shift'],
        ['work_hours_per_day', 'Work Hours / Day', 'num'],
        ['weekly_off', 'Weekly Off', 'select', 'weekly_off'],
        ['notice_period_days', 'Notice Period (Days)', 'num'],
        ['probation_period_months', 'Probation Period (Months)', 'num'],
        ['probation_end_date', 'Probation End Date', 'date'],
        ['reports_to', 'Reports To (Manager)', 'select', 'reports_to'],
        ['rehire_eligible', 'Rehire Eligible?', 'bool'],
        ['is_block', 'Is Block?', 'bool'],
        ['is_late', 'Is Late?', 'bool'],
        ['is_probation', 'Is Probation?', 'bool'],
        ['is_contractor', 'Is Contractor?', 'bool'],
        ['contractor_id', 'Contractor', 'select', 'contractor_id'],
        ['linkedin', 'LinkedIn', 'text'],
        ['facebook', 'Facebook', 'text'],
        ['remark', 'Remark', 'multiline'],
        ['resignation_date', 'Resignation Date', 'date'],
        ['last_working_date', 'Last Working Date', 'date'],
      ],
    },
    {
      'title': 'Personal & KYC',
      'icon': Icons.badge_outlined,
      'fields': [
        ['nationality', 'Nationality', 'text'],
        ['religion', 'Religion', 'select', 'religion'],
        ['caste', 'Caste Category', 'select', 'caste'],
        ['physically_handicapped', 'Differently Abled?', 'bool'],
        ['aadhar_number', 'Aadhaar Number', 'text'],
        ['pan_number', 'PAN Number', 'text'],
        ['uan_number', 'UAN Number (PF)', 'text'],
        ['esic_number', 'ESIC Number', 'text'],
        ['passport_number', 'Passport Number', 'text'],
        ['passport_expiry', 'Passport Expiry', 'date'],
        ['driving_license', 'Driving License No.', 'text'],
        ['dl_expiry', 'DL Expiry Date', 'date'],
        ['emergency_name', 'Emergency Contact Name', 'text'],
        ['emergency_relation', 'Emergency Relationship', 'select', 'emergency_relation'],
        ['emergency_phone', 'Emergency Phone', 'text'],
        ['emergency_address', 'Emergency Address', 'multiline'],
      ],
    },
    {
      'title': 'Bank Details',
      'icon': Icons.account_balance_outlined,
      'fields': [
        ['bank_account_holder', 'Account Holder Name', 'text'],
        ['bank_name', 'Bank Name', 'text'],
        ['bank_account_number', 'Account Number', 'text'],
        ['bank_ifsc', 'IFSC Code', 'text'],
        ['bank_branch', 'Branch Name', 'text'],
        ['bank_account_type', 'Account Type', 'select', 'bank_account_type'],
      ],
    },
    {
      'title': 'Education',
      'icon': Icons.school_outlined,
      'fields': [
        ['highest_qualification', 'Highest Qualification', 'select', 'highest_qualification'],
        ['university', 'University / Board', 'text'],
        ['passing_year', 'Passing Year', 'num'],
        ['specialization', 'Specialization', 'text'],
        ['prev_company', 'Previous Company', 'text'],
        ['prev_designation', 'Previous Designation', 'text'],
        ['total_experience_yrs', 'Total Experience (Yrs)', 'num'],
        ['prev_from_date', 'From Date', 'date'],
        ['prev_to_date', 'To Date', 'date'],
        ['prev_leaving_reason', 'Reason for Leaving', 'multiline'],
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Api.profileEditData();
      if (res['ok'] == true) {
        final values = (res['values'] as Map?) ?? {};
        _options = (res['options'] as Map?)?.cast<String, dynamic>() ?? {};
        _readonly['employee_code'] = '${values['employee_code'] ?? ''}';
        _readonly['employee_id'] = '${values['employee_id'] ?? ''}';
        _photo = '${values['profile_photo'] ?? ''}';
        try {
          final dj = jsonDecode('${values['documents_json'] ?? '[]'}');
          if (dj is List) _docs = dj.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } catch (_) {
          _docs = [];
        }
        for (final sec in _sections) {
          for (final f in (sec['fields'] as List)) {
            final key = f[0] as String;
            final type = f[2] as String;
            final cur = '${values[key] ?? ''}';
            if (type == 'text' || type == 'num' || type == 'multiline') {
              _ctrls[key] = TextEditingController(text: cur);
            } else {
              _vals[key] = cur;
            }
          }
        }
      } else {
        _error = res['error']?.toString() ?? 'Failed to load';
      }
    } catch (e) {
      _error = 'Network error';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final body = <String, dynamic>{};
    _ctrls.forEach((k, c) => body[k] = c.text);
    _vals.forEach((k, v) => body[k] = v);
    body['profile_photo'] = _photo;
    body['documents_json'] = jsonEncode(_docs);
    try {
      final res = await Api.profileSave(body);
      if (res['ok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully'), duration: Duration(seconds: 2)));
          Navigator.pop(context, true);
        }
      } else {
        _snack(res['error']?.toString() ?? 'Save failed');
      }
    } catch (e) {
      _snack('Network error while saving');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(seconds: 3)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (!_loading && _error == null)
            TextButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.red)))
              : Column(children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(4, 4, 4, 10),
                          child: Text('Salary details view-only hain — HR se contact karein.',
                              style: TextStyle(fontSize: 12, color: AppColors.text3, fontWeight: FontWeight.w600)),
                        ),
                        _photoCard(),
                        _readonlyCard(),
                        for (int i = 0; i < _sections.length; i++) _sectionTile(_sections[i], i == 0),
                        _docsCard(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ]),
      bottomNavigationBar: (_loading || _error != null)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined, size: 19),
                    label: Text(_saving ? 'Saving...' : 'Save Profile',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
                ),
              ),
            ),
    );
  }

  Uint8List? _decodeDataUri(String uri) {
    try {
      final b64 = uri.contains(',') ? uri.split(',').last : uri;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Widget _smallBtn(String label, IconData icon, VoidCallback onTap, {bool danger = false}) {
    final c = danger ? AppColors.red : AppColors.primary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: c),
      label: Text(label, style: TextStyle(fontSize: 12.5, color: c, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: c.withOpacity(.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _photoCard() {
    final bytes = _photo.startsWith('data:') ? _decodeDataUri(_photo) : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: cardDecoration(),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.photo_camera_outlined, size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Profile Photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text)),
        ]),
        const SizedBox(height: 12),
        CircleAvatar(
          radius: 46,
          backgroundColor: AppColors.primary.withOpacity(.10),
          backgroundImage: bytes != null ? MemoryImage(bytes) : null,
          child: bytes == null ? const Icon(Icons.person, size: 46, color: AppColors.primary) : null,
        ),
        const SizedBox(height: 12),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          _smallBtn('Camera', Icons.camera_alt_outlined, () => _pickPhoto(ImageSource.camera)),
          _smallBtn('Gallery', Icons.image_outlined, () => _pickPhoto(ImageSource.gallery)),
          if (_photo.isNotEmpty)
            _smallBtn('Remove', Icons.delete_outline, () => setState(() => _photo = ''), danger: true),
        ]),
      ]),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      XFile? x = await _picker.pickImage(source: source, maxWidth: 800, imageQuality: 70);
      // Android can drop the picked result if the activity is recreated during
      // capture/selection. Recover it instead of silently returning null.
      if (x == null) {
        final LostDataResponse lost = await _picker.retrieveLostData();
        if (!lost.isEmpty && lost.file != null) x = lost.file;
      }
      if (x == null) {
        _snack('Koi image select nahi hui (picker null).');
        return;
      }
      final raw = await x.readAsBytes();
      if (raw.isEmpty) {
        _snack('Image read fail (0 bytes).');
        return;
      }
      if (!mounted) return;
      // Open the in-app crop screen (pure Dart via crop_your_image, no native cropper).
      final Uint8List? cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(builder: (_) => PhotoCropScreen(imageBytes: raw)),
      );
      if (cropped == null) return; // user cancelled crop
      setState(() => _photo = 'data:image/jpeg;base64,${base64Encode(cropped)}');
      _snack('Photo cropped (${(cropped.length / 1024).toStringAsFixed(0)} KB).');
    } catch (e) {
      _snack('Pick error: ${e.toString()}');
    }
  }

  static const List<String> _docTypes = [
    'Offer Letter', 'Appointment Letter', 'Aadhaar Card', 'PAN Card', 'Passport Copy',
    'Driving License', '10th Certificate', '12th Certificate', 'Degree Certificate',
    'Experience Letter', 'Relieving Letter', 'Salary Slip', 'Bank Passbook', 'Photo', 'Other',
  ];

  Widget _docsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      decoration: cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.attach_file, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Documents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.text))),
          TextButton.icon(
            onPressed: _addDoc,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
        if (_docs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text('No documents uploaded yet.', style: TextStyle(fontSize: 12.5, color: AppColors.text3)),
          )
        else
          ..._docs.asMap().entries.map((e) => _docRow(e.key, e.value)),
      ]),
    );
  }

  Widget _docRow(int i, Map<String, dynamic> dmap) {
    final name = '${dmap['name'] ?? dmap['filename'] ?? 'Document'}';
    final fn = '${dmap['filename'] ?? ''}';
    final kb = (((dmap['size'] ?? 0) as num) / 1024).round();
    final isPdf = fn.toLowerCase().endsWith('.pdf');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined, size: 22, color: AppColors.text2),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.text)),
          if (fn.isNotEmpty)
            Text('$fn  \u00b7  $kb KB', style: const TextStyle(fontSize: 11, color: AppColors.text3)),
        ])),
        IconButton(
          onPressed: () => setState(() => _docs.removeAt(i)),
          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.red),
        ),
      ]),
    );
  }

  Future<void> _addDoc() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text('Select Document Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
            ..._docTypes.map((t) => ListTile(
                  dense: true,
                  title: Text(t, style: const TextStyle(fontSize: 14)),
                  onTap: () => Navigator.pop(context, t),
                )),
          ],
        ),
      ),
    );
    if (type == null) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      final bytes = f.bytes;
      if (bytes == null) {
        _snack('Could not read file');
        return;
      }
      if (bytes.length > 5 * 1024 * 1024) {
        _snack('File too large (max 5MB)');
        return;
      }
      final ext = (f.extension ?? '').toLowerCase();
      final mime = ext == 'pdf' ? 'application/pdf' : (ext == 'png' ? 'image/png' : 'image/jpeg');
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      setState(() {
        _docs.add({
          'name': type,
          'type': type,
          'filename': f.name,
          'size': bytes.length,
          'base64': dataUri,
          'uploaded_at': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      _snack('Could not add document');
    }
  }

  Widget _readonlyCard() {
    final code = _readonly['employee_code'] ?? '';
    final bio = _readonly['employee_id'] ?? '';
    if (code.isEmpty && bio.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      decoration: cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: const [
          Icon(Icons.lock_outline, size: 16, color: AppColors.text3),
          SizedBox(width: 7),
          Text('Read-only (HR only)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text3)),
        ]),
        const SizedBox(height: 8),
        _roRow('Employee Code', code),
        _roRow('Employee ID (Biometric)', bio),
      ]),
    );
  }

  Widget _roRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 150, child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.text3, fontWeight: FontWeight.w600))),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13.5, color: AppColors.text, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  Widget _sectionTile(Map<String, dynamic> sec, bool expanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 15),
          leading: Icon(sec['icon'] as IconData, color: AppColors.primary, size: 20),
          title: Text(sec['title'] as String,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text)),
          childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 12),
          children: [
            for (final f in (sec['fields'] as List)) _field(f as List),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 5),
        child: Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.text3, fontWeight: FontWeight.w700, letterSpacing: .2)),
      );

  InputDecoration _dec() => InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: AppColors.border)),
      );

  Widget _field(List f) {
    final key = f[0] as String;
    final label = f[1] as String;
    final type = f[2] as String;

    if (type == 'bool') {
      final on = _vals[key] == 'yes';
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.text, fontWeight: FontWeight.w600))),
          Switch(
            value: on,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _vals[key] = v ? 'yes' : 'no'),
          ),
        ]),
      );
    }

    if (type == 'select') {
      final optKey = f.length > 3 ? f[3] as String : '';
      final raw = (_options[optKey] as List?) ?? [];
      // Build list of {value, display}
      final items = <Map<String, String>>[];
      for (final o in raw) {
        if (o is Map) {
          items.add({'value': '${o['id']}', 'display': '${o['label']}'});
        } else {
          items.add({'value': '$o', 'display': '$o'});
        }
      }
      String cur = _vals[key] ?? '';
      // Ensure current value is present in items (avoid dropdown assertion)
      if (cur.isNotEmpty && !items.any((it) => it['value'] == cur)) {
        items.insert(0, {'value': cur, 'display': cur});
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        DropdownButtonFormField<String>(
          value: cur.isEmpty ? null : cur,
          isExpanded: true,
          decoration: _dec(),
          hint: const Text('Select', style: TextStyle(fontSize: 13)),
          items: [
            const DropdownMenuItem<String>(value: '', child: Text('— Select —', style: TextStyle(fontSize: 13))),
            ...items.map((it) => DropdownMenuItem<String>(
                  value: it['value'],
                  child: Text(it['display'] ?? '', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (v) => setState(() => _vals[key] = v ?? ''),
        ),
      ]);
    }

    if (type == 'date') {
      final cur = _vals[key] ?? '';
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label(label),
        InkWell(
          onTap: () => _pickDate(key),
          child: InputDecorator(
            decoration: _dec(),
            child: Row(children: [
              Expanded(child: Text(cur.isEmpty ? 'DD-MM-YYYY' : cur,
                  style: TextStyle(fontSize: 13.5, color: cur.isEmpty ? AppColors.text3 : AppColors.text))),
              if (cur.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _vals[key] = ''),
                  child: const Icon(Icons.clear, size: 16, color: AppColors.text3),
                ),
              const SizedBox(width: 4),
              const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.text3),
            ]),
          ),
        ),
      ]);
    }

    // text / num / multiline
    final ctrl = _ctrls[key];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      TextField(
        controller: ctrl,
        keyboardType: type == 'num'
            ? const TextInputType.numberWithOptions(decimal: true)
            : (type == 'multiline' ? TextInputType.multiline : TextInputType.text),
        maxLines: type == 'multiline' ? 3 : 1,
        style: const TextStyle(fontSize: 13.5),
        decoration: _dec(),
      ),
    ]);
  }

  Future<void> _pickDate(String key) async {
    DateTime init = DateTime.now();
    final cur = _vals[key] ?? '';
    if (cur.isNotEmpty) {
      final p = DateTime.tryParse(cur);
      if (p != null) init = p;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() => _vals[key] = '${picked.year}-$m-$d');
    }
  }
}
