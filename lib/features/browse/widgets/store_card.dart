import 'package:flutter/material.dart';
import '../../flyer/models/store.dart';

enum CardStatus { newBadge, untilText, previewBadge, expiringText }

class StoreCard extends StatelessWidget {
  final Store store;
  final String? statusLabel;
  final CardStatus statusType;
  final VoidCallback? onTap;

  const StoreCard({
    super.key,
    required this.store,
    this.statusLabel,
    this.statusType = CardStatus.newBadge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String thumbnail =
        store.pages.isNotEmpty ? store.pages.first.imagePath : '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (statusLabel != null) _buildStatus(),
                    ],
                  ),
                ),
                Icon(
                  Icons.favorite_border,
                  size: 20,
                  color: Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF2F3F5),
                  child: thumbnail.isEmpty
                      ? const Icon(
                          Icons.image_outlined,
                          size: 40,
                          color: Colors.grey,
                        )
                      : Image.asset(thumbnail, fit: BoxFit.cover),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    switch (statusType) {
      case CardStatus.newBadge:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            statusLabel!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case CardStatus.previewBadge:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            statusLabel!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case CardStatus.untilText:
        return Text(
          statusLabel!,
          style: const TextStyle(
            color: Color(0xFF0071CE),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
      case CardStatus.expiringText:
        return Text(
          statusLabel!,
          style: const TextStyle(
            color: Color(0xFFD32F2F),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }
}
