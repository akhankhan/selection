import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/config/legal_documents_service.dart';
import '../../../core/theme/app_theme_extension.dart';

enum LegalTermsFooterStyle { compact, full }

class LegalTermsFooter extends StatefulWidget {
  const LegalTermsFooter({
    super.key,
    this.style = LegalTermsFooterStyle.compact,
    this.padding = EdgeInsets.zero,
  });

  final LegalTermsFooterStyle style;
  final EdgeInsetsGeometry padding;

  @override
  State<LegalTermsFooter> createState() => _LegalTermsFooterState();
}

class _LegalTermsFooterState extends State<LegalTermsFooter> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _open(LegalDocumentType.termsOfService);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _open(LegalDocumentType.privacyPolicy);
  }

  void _open(LegalDocumentType type) {
    LegalDocumentsService.instance.open(context, type);
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final normal = TextStyle(
      fontSize: 11.5,
      color: appTheme.subtitle,
      height: 1.45,
    );
    final link = TextStyle(
      fontSize: 11.5,
      color: context.brandBlue,
      fontWeight: FontWeight.bold,
      height: 1.45,
    );

    final children = widget.style == LegalTermsFooterStyle.compact
        ? <InlineSpan>[
            TextSpan(text: 'By continuing, you agree to our ', style: normal),
            TextSpan(
              text: 'Terms of Use',
              style: link,
              recognizer: _termsRecognizer,
            ),
            TextSpan(text: ' and ', style: normal),
            TextSpan(
              text: 'Privacy Policy',
              style: link,
              recognizer: _privacyRecognizer,
            ),
            TextSpan(text: '.', style: normal),
          ]
        : <InlineSpan>[
            TextSpan(text: 'By continuing, you agree to our ', style: normal),
            TextSpan(
              text: 'Terms of Use',
              style: link,
              recognizer: _termsRecognizer,
            ),
            TextSpan(
              text:
                  ' and the collection and use of your data as described in our ',
              style: normal,
            ),
            TextSpan(
              text: 'Privacy Policy',
              style: link,
              recognizer: _privacyRecognizer,
            ),
            TextSpan(
              text:
                  '. If you\'d like to opt out or learn more about your data options, please review our ',
              style: normal,
            ),
            TextSpan(
              text: 'Privacy Policy',
              style: link,
              recognizer: _privacyRecognizer,
            ),
            TextSpan(text: '.', style: normal),
          ];

    return Padding(
      padding: widget.padding,
      child: Text.rich(
        TextSpan(children: children),
        textAlign: TextAlign.center,
      ),
    );
  }
}
