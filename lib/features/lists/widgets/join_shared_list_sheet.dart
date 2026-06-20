import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';
import '../../settings/widgets/sign_in_required_gate.dart';
import '../services/shared_list_service.dart';

class JoinSharedListSheet extends StatefulWidget {
  const JoinSharedListSheet({super.key, this.initialCode});

  final String? initialCode;

  static Future<void> show(
    BuildContext context, {
    String? initialCode,
  }) async {
    final signedIn = await ensureSignedIn(context);
    if (!signedIn || !context.mounted) return;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => JoinSharedListSheet(initialCode: initialCode),
    );
  }

  @override
  State<JoinSharedListSheet> createState() => _JoinSharedListSheetState();
}

class _JoinSharedListSheetState extends State<JoinSharedListSheet> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() => _loading = true);
    try {
      await SharedListService.instance.joinWithInviteCode(_codeController.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Shared list joined and items added.'),
          backgroundColor: context.brandBlue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('StateError: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: appTheme.subtitle.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Join shared list',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appTheme.navyText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.initialCode == null
                  ? 'Enter the invite code from your friend\'s shared list.'
                  : 'Invite code loaded from your link. Tap Join list to continue.',
              style: TextStyle(color: appTheme.subtitle, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Invite code',
                filled: true,
                fillColor: appTheme.searchFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _join,
                style: FilledButton.styleFrom(
                  backgroundColor: context.brandBlue,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Join list',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
