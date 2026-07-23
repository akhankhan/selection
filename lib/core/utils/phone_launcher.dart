import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the device dialer for restaurant pickup orders (no in-app checkout).
class PhoneLauncher {
  PhoneLauncher._();

  /// Digits (and leading +) only — safe for `tel:` URIs.
  static String? normalize(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final cleaned = trimmed.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty || cleaned == '+') return null;
    return cleaned;
  }

  static Future<void> callForPickup(
    BuildContext context, {
    required String? phone,
    String? restaurantName,
  }) async {
    final who = (restaurantName != null && restaurantName.trim().isNotEmpty)
        ? restaurantName.trim()
        : 'this restaurant';
    final number = normalize(phone);
    final display = phone?.trim();

    if (number == null) {
      if (!context.mounted) return;
      await _showMessage(
        context,
        title: 'No phone number',
        body:
            'Add a phone number for $who in the admin panel '
            '(Restaurants → Edit → Phone), then try again.',
      );
      return;
    }

    // Prefer Uri.parse — Uri(scheme/path) can mishandle + / leading zeros.
    final uri = Uri.parse('tel:$number');

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched || !context.mounted) return;

      await _showDialFallback(
        context,
        who: who,
        displayPhone: display ?? number,
        number: number,
      );
    } catch (_) {
      if (!context.mounted) return;
      await _showDialFallback(
        context,
        who: who,
        displayPhone: display ?? number,
        number: number,
      );
    }
  }

  static Future<void> _showDialFallback(
    BuildContext context, {
    required String who,
    required String displayPhone,
    required String number,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Call for pickup'),
        content: Text(
          'Could not open the dialer on this device '
          '(common on emulators).\n\n'
          '$who\n$displayPhone',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: displayPhone));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Copy number'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await launchUrl(
                  Uri.parse('tel:$number'),
                  mode: LaunchMode.platformDefault,
                );
              } catch (_) {}
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showMessage(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
