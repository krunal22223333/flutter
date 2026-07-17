import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api.dart';

IconData _celebIcon(String? type) {
  switch (type) {
    case 'birthday':
      return Icons.cake;
    case 'work_anniversary':
      return Icons.workspace_premium;
    case 'marriage_anniversary':
      return Icons.favorite;
    default:
      return Icons.celebration;
  }
}

Color _celebColor(String? type) {
  switch (type) {
    case 'birthday':
      return AppColors.primary;
    case 'work_anniversary':
      return AppColors.orange;
    case 'marriage_anniversary':
      return AppColors.red;
    default:
      return AppColors.purple;
  }
}

/// Popup shown on app open when there are celebrations today.
/// [items] = today's celebrations (self entries are hidden from the wish list).
/// [myWishes] = wishes received by the current user today (user-wise).
Future<void> showCelebrationsDialog(BuildContext context, List items, {List myWishes = const []}) {
  return showDialog(
    context: context,
    builder: (ctx) {
      final wished = <int>{};
      return StatefulBuilder(builder: (ctx, setD) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.headerGrad1, AppColors.headerGrad2],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Row(children: const [
                  Icon(Icons.celebration, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text("Today's Celebrations",
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                ]),
              ),
              Flexible(
                child: Builder(builder: (ctx2) {
                  final others = items.where((c) => (c as Map)['is_self'] != true).toList();
                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(14),
                    children: [
                      if (myWishes.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8, left: 2),
                          child: Text('Wishes for you',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.text2)),
                        ),
                        ...myWishes.map((w) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: cardDecoration(),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                      color: AppColors.green.withOpacity(.12),
                                      borderRadius: BorderRadius.circular(9)),
                                  child: const Icon(Icons.volunteer_activism, color: AppColors.green, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text((w as Map)['from']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.text)),
                                    const SizedBox(height: 2),
                                    Text(w['text']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                                  ]),
                                ),
                                Text(w['at']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.text3)),
                              ]),
                            )),
                        if (others.isNotEmpty) const SizedBox(height: 6),
                      ],
                      ...List.generate(others.length, (i) {
                    final c = others[i] as Map;
                    final id = (c['id'] as num).toInt();
                    final type = c['type']?.toString();
                    final isSelf = c['is_self'] == true;
                    final done = wished.contains(id) || c['already_wished'] == true;
                    final col = _celebColor(type);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: cardDecoration(),
                      child: Row(children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: col.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_celebIcon(type), color: col, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c['name']?.toString() ?? '',
                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.text)),
                            const SizedBox(height: 2),
                            Text('${c['type_label'] ?? ''}  •  ${c['extra'] ?? ''}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.text3)),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        if (isSelf)
                          const Text('Your day!',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary))
                        else if (done)
                          Row(mainAxisSize: MainAxisSize.min, children: const [
                            Icon(Icons.check_circle, size: 16, color: AppColors.green),
                            SizedBox(width: 4),
                            Text('Wished', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.green)),
                          ])
                        else
                          ElevatedButton(
                            onPressed: () async {
                              final ok = await _openWishSheet(ctx, c);
                              if (ok == true) setD(() => wished.add(id));
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: col, foregroundColor: Colors.white, elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            child: const Text('Wish', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                      ]),
                    );
                      }),
                    ],
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                ),
              ),
            ]),
          ),
        );
      });
    },
  );
}

/// Editable pre-filled wish; returns true if the wish was sent.
Future<bool?> _openWishSheet(BuildContext context, Map c) {
  final isSelf = c['is_self'] == true;
  final initial = (isSelf ? c['self_wish'] : c['wish_template'])?.toString() ?? '';
  final ctl = TextEditingController(text: initial);
  bool sending = false;
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      return Padding(
        padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(ctx).viewInsets.bottom + 22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_celebIcon(c['type']?.toString()), color: _celebColor(c['type']?.toString()), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Wish ${c['name'] ?? ''}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.text)),
            ),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: ctl,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: AppColors.text),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF3F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: sending
                  ? null
                  : () async {
                      setS(() => sending = true);
                      final res = await Api.sendWish(
                          (c['id'] as num).toInt(), c['type']?.toString() ?? '', ctl.text.trim());
                      setS(() => sending = false);
                      if (res['ok'] == true) {
                        Navigator.pop(ctx, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Wish sent'), backgroundColor: AppColors.green));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(res['error']?.toString() ?? 'Failed'), backgroundColor: AppColors.red));
                      }
                    },
              icon: sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Icon(Icons.send, size: 18),
              label: const Text('Send Wish', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ),
        ]),
      );
    }),
  );
}
