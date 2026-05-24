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
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 40),
                      child: Text(
                        'Delete options',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.black87),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildOption(context, 'Delete all expired items', onDeleteExpired),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildOption(context, 'Delete checked items', onDeleteChecked),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildOption(context, 'Delete all items', onDeleteAll),
          const SizedBox(height: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
      ),
    );
  }
}
