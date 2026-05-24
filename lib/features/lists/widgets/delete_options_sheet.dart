import 'package:flutter/material.dart';

class DeleteOptionsSheet extends StatelessWidget {
  const DeleteOptionsSheet({
    super.key,
    required this.onDeleteExpired,
    required this.onDeleteChecked,
    required this.onDeleteAll,
  });

  final VoidCallback onDeleteExpired;
  final VoidCallback onDeleteChecked;
  final VoidCallback onDeleteAll;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onDeleteExpired,
    required VoidCallback onDeleteChecked,
    required VoidCallback onDeleteAll,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DeleteOptionsSheet(
        onDeleteExpired: onDeleteExpired,
        onDeleteChecked: onDeleteChecked,
        onDeleteAll: onDeleteAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 48), // Offsets the close button for perfect centering
                const Expanded(
                  child: Text(
                    'Delete options',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF5F6368)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
          _buildOption(context, 'Delete all expired items', onDeleteExpired),
          const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
          _buildOption(context, 'Delete checked items', onDeleteChecked),
          const Divider(height: 1, color: Color(0xFFEEEEEE), thickness: 1),
          _buildOption(context, 'Delete all items', onDeleteAll),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
