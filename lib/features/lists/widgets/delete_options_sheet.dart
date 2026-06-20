import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';

class DeleteOptionsSheet extends StatelessWidget {
  const DeleteOptionsSheet({
    super.key,
    required this.expiredCount,
    required this.checkedCount,
    required this.totalCount,
    required this.onDeleteExpired,
    required this.onDeleteChecked,
    required this.onDeleteAll,
  });

  final int expiredCount;
  final int checkedCount;
  final int totalCount;
  final VoidCallback onDeleteExpired;
  final VoidCallback onDeleteChecked;
  final VoidCallback onDeleteAll;

  static Future<void> show(
    BuildContext context, {
    required int expiredCount,
    required int checkedCount,
    required int totalCount,
    required VoidCallback onDeleteExpired,
    required VoidCallback onDeleteChecked,
    required VoidCallback onDeleteAll,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DeleteOptionsSheet(
        expiredCount: expiredCount,
        checkedCount: checkedCount,
        totalCount: totalCount,
        onDeleteExpired: onDeleteExpired,
        onDeleteChecked: onDeleteChecked,
        onDeleteAll: onDeleteAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    'Delete options',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.navyText,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: theme.chipInactive),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.border, thickness: 1),
          _buildOption(
            context,
            label: 'Delete all expired items',
            count: expiredCount,
            onTap: onDeleteExpired,
          ),
          Divider(height: 1, color: theme.border, thickness: 1),
          _buildOption(
            context,
            label: 'Delete checked items',
            count: checkedCount,
            onTap: onDeleteChecked,
          ),
          Divider(height: 1, color: theme.border, thickness: 1),
          _buildOption(
            context,
            label: 'Delete all items',
            count: totalCount,
            onTap: onDeleteAll,
            destructive: true,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String label,
    required int count,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final theme = context.appTheme;
    final destructiveColor = Theme.of(context).colorScheme.error;
    final enabled = count > 0;
    final color = !enabled
        ? theme.subtitle.withValues(alpha: 0.45)
        : destructive
        ? destructiveColor
        : theme.navyText;

    return InkWell(
      onTap: enabled
          ? () {
              Navigator.of(context).pop();
              onTap();
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (count > 0)
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: destructive
                      ? destructiveColor
                      : context.brandBlue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
