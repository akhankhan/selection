import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.url,
    required this.assetPath,
    this.firestoreHtml,
  });

  final String title;
  final String url;
  final String assetPath;
  final String? firestoreHtml;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  static const _stylesAsset = 'assets/legal/styles.css';

  late final WebViewController _controller;
  bool _loading = true;
  bool _error = false;
  Timer? _loadTimeout;
  Brightness? _loadedBrightness;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _finishLoading(),
        ),
      );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContent());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_loadedBrightness != null && _loadedBrightness != brightness) {
      _loadedBrightness = null;
      _reload();
    }
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final brightness = Theme.of(context).brightness;
    final background = Theme.of(context).scaffoldBackgroundColor;
    await _controller.setBackgroundColor(background);

    _loadTimeout?.cancel();
    _loadTimeout = Timer(const Duration(seconds: 10), () {
      if (mounted && _loading) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    });

    try {
      final firestoreHtml = widget.firestoreHtml?.trim();
      if (firestoreHtml != null && firestoreHtml.isNotEmpty) {
        await _controller.loadHtmlString(
          await _prepareHtml(firestoreHtml, brightness),
        );
        if (!mounted) return;
        _loadedBrightness = brightness;
        _finishLoading();
        return;
      }

      final hosted = await _tryLoadHostedHtml();
      if (!mounted) return;

      if (hosted != null) {
        await _controller.loadHtmlString(
          await _prepareHtml(hosted, brightness),
        );
      } else {
        final html = await _loadBundledHtml(brightness);
        await _controller.loadHtmlString(html);
      }
      _loadedBrightness = brightness;
      _finishLoading();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<String> _prepareHtml(String html, Brightness brightness) async {
    var prepared = await _inlineStyles(html);
    prepared = _applyThemeClass(prepared, brightness);
    prepared = _injectAppThemeStyles(prepared, brightness);
    return prepared;
  }

  String _applyThemeClass(String html, Brightness brightness) {
    final themeClass =
        brightness == Brightness.dark ? 'theme-dark' : 'theme-light';

    return html.replaceFirstMapped(
      RegExp(r'<html(\s[^>]*)?>', caseSensitive: false),
      (match) {
        final attrs = match.group(1) ?? '';
        final classPattern = RegExp(r'\sclass="([^"]*)"');

        if (classPattern.hasMatch(attrs)) {
          final updatedAttrs = attrs.replaceFirstMapped(classPattern, (m) {
            final classes = (m.group(1) ?? '')
                .split(' ')
                .where((c) => c != 'theme-dark' && c != 'theme-light')
                .join(' ');
            final merged =
                classes.isEmpty ? themeClass : '$classes $themeClass';
            return ' class="$merged"';
          });
          return '<html$updatedAttrs>';
        }

        return '<html$attrs class="$themeClass">';
      },
    );
  }

  String _injectAppThemeStyles(String html, Brightness brightness) {
    final withoutPrevious = html.replaceAll(
      RegExp(r'<style id="flutter-app-theme">[\s\S]*?</style>'),
      '',
    );

    final isDark = brightness == Brightness.dark;
    final bg = isDark ? '#121212' : '#ffffff';
    final text = isDark ? '#e8eaed' : '#1a1a2e';
    final muted = isDark ? '#9aa0a6' : '#5c6370';
    final accent = isDark ? '#4da3ff' : '#0071ce';
    final card = isDark ? '#252525' : '#f4f6f8';

    final themeBlock = '''
<style id="flutter-app-theme">
  html, body, main {
    background-color: $bg !important;
    color: $text !important;
  }
  h1, a { color: $accent !important; }
  h2, p, li, strong { color: $text !important; }
  .updated { color: $muted !important; }
  .card { background-color: $card !important; }
</style>''';

    if (withoutPrevious.contains('</head>')) {
      return withoutPrevious.replaceFirst('</head>', '$themeBlock</head>');
    }
    return '$themeBlock$withoutPrevious';
  }

  Future<String> _inlineStyles(String html) async {
    final linkPattern = RegExp(r'<link rel="stylesheet" href="[^"]+"\s*/?>');
    if (html.contains('<style>') && !linkPattern.hasMatch(html)) {
      return html;
    }

    try {
      final css = await rootBundle.loadString(_stylesAsset);
      if (linkPattern.hasMatch(html)) {
        return html.replaceFirst(linkPattern, '<style>$css</style>');
      }
      if (!html.contains('<style>')) {
        return html.replaceFirst('</head>', '<style>$css</style></head>');
      }
      return html;
    } catch (_) {
      return html;
    }
  }

  Future<String?> _tryLoadHostedHtml() async {
    try {
      final response = await http.get(Uri.parse(widget.url)).timeout(
            const Duration(seconds: 6),
          );
      if (response.statusCode == 200 && response.body.trim().isNotEmpty) {
        return response.body;
      }
    } catch (_) {
      // fall through to bundled copy
    }
    return null;
  }

  Future<String> _loadBundledHtml(Brightness brightness) async {
    final html = await rootBundle.loadString(widget.assetPath);
    return _prepareHtml(html, brightness);
  }

  void _finishLoading() {
    _loadTimeout?.cancel();
    if (mounted) setState(() => _loading = false);
  }

  void _reload() {
    setState(() {
      _loading = true;
      _error = false;
    });
    _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor),
        ),
      ),
      body: Stack(
        children: [
          if (!_error) WebViewWidget(controller: _controller),
          if (_error)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load this document.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          if (_loading && !_error)
            ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
