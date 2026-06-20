import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../../features/lists/services/shared_list_service.dart';

typedef InviteCodeHandler = void Function(String code);

class InviteDeepLinkService {
  InviteDeepLinkService._();

  static final InviteDeepLinkService instance = InviteDeepLinkService._();

  static const customScheme = 'menu2goexpress';

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  String? _pendingCode;
  InviteCodeHandler? _handler;

  String? get pendingCode => _pendingCode;

  Future<void> initialize({InviteCodeHandler? onCode}) async {
    _handler = onCode;
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _storeCode(parseInviteCode(initial));
      }
    } catch (e) {
      debugPrint('[InviteDeepLink] initial link failed: $e');
    }

    await _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _storeCode(parseInviteCode(uri)),
      onError: (Object error) {
        debugPrint('[InviteDeepLink] stream error: $error');
      },
    );
  }

  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  String? parseInviteCode(Uri uri) {
    final queryCode = uri.queryParameters['code'];
    if (queryCode != null && queryCode.trim().isNotEmpty) {
      return _normalizeCode(queryCode);
    }

    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();

    if (uri.scheme == customScheme && uri.host == 'join' && segments.isNotEmpty) {
      return _normalizeCode(segments.first);
    }

    final joinIndex = segments.indexOf('join');
    if (joinIndex >= 0 && joinIndex + 1 < segments.length) {
      return _normalizeCode(segments[joinIndex + 1]);
    }

    return null;
  }

  String? consumePendingCode() {
    final code = _pendingCode;
    _pendingCode = null;
    return code;
  }

  void _storeCode(String? code) {
    if (code == null || code.isEmpty) return;
    _pendingCode = code;
    _handler?.call(code);
  }

  String? _normalizeCode(String raw) {
    final cleaned = raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (cleaned.length < 6) return null;
    return cleaned;
  }

  String buildCustomSchemeLink(String inviteCode) {
    return '$customScheme://join/${inviteCode.toUpperCase()}';
  }

  String buildWebInviteLink(String inviteCode) {
    return '${SharedListService.inviteBaseUrl}/${inviteCode.toUpperCase()}';
  }
}
