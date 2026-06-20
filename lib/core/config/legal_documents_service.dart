import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../features/settings/screens/legal_document_screen.dart';

enum LegalDocumentType {
  termsOfService(
    'Terms Of Service',
    'assets/legal/terms-of-service.html',
    'terms_of_service',
  ),
  enhancedNotice(
    'Enhanced Notice',
    'assets/legal/enhanced-notice.html',
    'enhanced_notice',
  ),
  privacyPolicy(
    'Privacy Policy',
    'assets/legal/privacy-policy.html',
    'privacy_policy',
  );

  const LegalDocumentType(this.title, this.assetPath, this.policyId);
  final String title;
  final String assetPath;
  final String policyId;
}

class LegalDocuments {
  const LegalDocuments({
    required this.termsOfServiceUrl,
    required this.enhancedNoticeUrl,
    required this.privacyPolicyUrl,
    required this.supportEmail,
  });

  static const String hostingBase = 'https://selection-admin.web.app';

  static const LegalDocuments defaults = LegalDocuments(
    termsOfServiceUrl: '$hostingBase/terms-of-service.html',
    enhancedNoticeUrl: '$hostingBase/enhanced-notice.html',
    privacyPolicyUrl: '$hostingBase/privacy-policy.html',
    supportEmail: 'support@selection.app',
  );

  final String termsOfServiceUrl;
  final String enhancedNoticeUrl;
  final String privacyPolicyUrl;
  final String supportEmail;

  String urlFor(LegalDocumentType type) => switch (type) {
        LegalDocumentType.termsOfService => termsOfServiceUrl,
        LegalDocumentType.enhancedNotice => enhancedNoticeUrl,
        LegalDocumentType.privacyPolicy => privacyPolicyUrl,
      };

  factory LegalDocuments.fromFirestore(Map<String, dynamic> data) {
    String pick(String key, String fallback) {
      final value = (data[key] as String?)?.trim();
      return value != null && value.isNotEmpty ? value : fallback;
    }

    return LegalDocuments(
      termsOfServiceUrl: pick(
        'termsOfServiceUrl',
        defaults.termsOfServiceUrl,
      ),
      enhancedNoticeUrl: pick(
        'enhancedNoticeUrl',
        defaults.enhancedNoticeUrl,
      ),
      privacyPolicyUrl: pick(
        'privacyPolicyUrl',
        defaults.privacyPolicyUrl,
      ),
      supportEmail: pick('supportEmail', defaults.supportEmail),
    );
  }
}

class LegalDocumentsService {
  LegalDocumentsService._();

  static final LegalDocumentsService instance = LegalDocumentsService._();

  LegalDocuments? _configCache;
  final Map<String, String?> _policyHtmlCache = {};

  Future<LegalDocuments> load() async {
    if (_configCache != null) return _configCache!;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('legal')
          .get();
      _configCache = snap.exists && snap.data() != null
          ? LegalDocuments.fromFirestore(snap.data()!)
          : LegalDocuments.defaults;
    } catch (e) {
      debugPrint('[LegalDocuments] load failed: $e');
      _configCache = LegalDocuments.defaults;
    }
    return _configCache!;
  }

  /// Loads published HTML from Firestore `legal_policies/{policyId}`.
  Future<String?> fetchPublishedPolicyHtml(String policyId) async {
    if (_policyHtmlCache.containsKey(policyId)) {
      return _policyHtmlCache[policyId];
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('legal_policies')
          .doc(policyId)
          .get();
      if (!snap.exists) {
        _policyHtmlCache[policyId] = null;
        return null;
      }
      final data = snap.data();
      final published = data?['isPublished'] == true;
      final html = (data?['htmlContent'] as String?)?.trim();
      if (!published ||
          html == null ||
          html.isEmpty ||
          html.contains('Update this content in the admin panel')) {
        _policyHtmlCache[policyId] = null;
        return null;
      }
      _policyHtmlCache[policyId] = html;
      return html;
    } catch (e) {
      debugPrint('[LegalDocuments] policy load failed: $e');
      return null;
    }
  }

  void clearPolicyCache([String? policyId]) {
    if (policyId == null) {
      _policyHtmlCache.clear();
    } else {
      _policyHtmlCache.remove(policyId);
    }
  }

  Future<void> open(BuildContext context, LegalDocumentType type) async {
    final docs = await load();
    final firestoreHtml = await fetchPublishedPolicyHtml(type.policyId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LegalDocumentScreen(
          title: type.title,
          url: docs.urlFor(type),
          assetPath: type.assetPath,
          firestoreHtml: firestoreHtml,
        ),
      ),
    );
  }
}
