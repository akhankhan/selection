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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _finishLoading(),
        ),
      );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadContent());
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    super.dispose();
  }

  Future<void> _loadContent() async {
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
        await _controller.loadHtmlString(await _inlineStyles(firestoreHtml));
        if (!mounted) return;
        _finishLoading();
        return;
      }

      final hosted = await _tryLoadHostedHtml();
      if (!mounted) return;

      if (hosted != null) {
        final baseUrl = widget.url.substring(0, widget.url.lastIndexOf('/') + 1);
        await _controller.loadHtmlString(hosted, baseUrl: baseUrl);
      } else {
        final html = await _loadBundledHtml();
        await _controller.loadHtmlString(html);
      }
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

  Future<String> _inlineStyles(String html) async {
    if (html.contains('<style>') || !html.contains('styles.css')) {
      return html;
    }
    try {
      final css = await rootBundle.loadString(_stylesAsset);
      return html.replaceFirst(
        RegExp(r'<link rel="stylesheet" href="[^"]+"\s*/>'),
        '<style>$css</style>',
      );
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

  Future<String> _loadBundledHtml() async {
    final html = await rootBundle.loadString(widget.assetPath);
    final css = await rootBundle.loadString(_stylesAsset);
    return html.replaceFirst(
      RegExp(r'<link rel="stylesheet" href="[^"]+"\s*/>'),
      '<style>$css</style>',
    );
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
