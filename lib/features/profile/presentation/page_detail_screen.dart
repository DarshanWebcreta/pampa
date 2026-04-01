import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pampa/core/values/app_text_value.dart';
import 'package:pampa/core/values/colors.dart';
import 'package:pampa/core/widgets/text_widget.dart';
import 'package:pampa/data/service/apiservice.dart';
import 'package:pampa/data/service/di.dart';

class PageDetailScreen extends StatefulWidget {
  final String slug;
  final String title;

  const PageDetailScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  @override
  State<PageDetailScreen> createState() => _PageDetailScreenState();
}

class _PageDetailScreenState extends State<PageDetailScreen> {
  final _api = getIt<ApiService>();
  InAppWebViewController? _webController;

  bool _loading = true;
  bool _webViewReady = false;
  String _error = '';
  String? _pendingHtml;

  @override
  void initState() {
    super.initState();
    _fetchPage();
  }

  Future<void> _fetchPage() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await _api.getPageBySlug(widget.slug);
      final map = response as Map<String, dynamic>;
      if (map['status'] == true) {
        final data = map['data'] as Map<String, dynamic>;
        final raw = data['content'] as String? ?? '';
        final html = _buildHtml(_decodeHtmlEntities(raw));
        if (_webViewReady && _webController != null) {
          await _webController!.loadData(
            data: html,
            mimeType: 'text/html',
            encoding: 'utf-8',
          );
        } else {
          _pendingHtml = html;
        }
        setState(() => _loading = false);
      } else {
        setState(() {
          _error = map['message']?.toString() ?? 'Failed to load page.';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Failed to load page.';
        _loading = false;
      });
    }
  }

  String _decodeHtmlEntities(String html) {
    return html
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', '\u00A0');
  }

  String _buildHtml(String content) => '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      font-size: 15px;
      line-height: 1.7;
      color: #323232;
      padding: 20px;
      margin: 0;
      background: #fdf8fa;
    }
    h1 { font-size: 20px; font-weight: 700; color: #5A1837; margin-top: 0; }
    h2 { font-size: 16px; font-weight: 600; color: #5A1837; margin-top: 20px; }
    h3 { font-size: 15px; font-weight: 600; }
    p  { margin: 8px 0; }
    ul, ol { padding-left: 20px; }
    li { margin-bottom: 4px; }
    a  { color: #5A1837; }
    strong { font-weight: 600; }
  </style>
</head>
<body>$content</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.authBg,
      appBar: AppBar(
        backgroundColor: AppColor.authBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColor.darkGrey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AppText(
          widget.title,
          fontSize: FontSizes.medium,
          fontWeight: FontWeights.bold,
          color: AppColor.darkGrey,
        ),
        centerTitle: false,
      ),
      body: _error.isNotEmpty
          ? _buildError()
          : Stack(
              children: [
                InAppWebView(
                  initialSettings: InAppWebViewSettings(
                    transparentBackground: true,
                    disableHorizontalScroll: true,
                    supportZoom: false,
                  ),
                  onWebViewCreated: (controller) {
                    _webController = controller;
                    _webViewReady = true;
                    if (_pendingHtml != null) {
                      controller.loadData(
                        data: _pendingHtml!,
                        mimeType: 'text/html',
                        encoding: 'utf-8',
                      );
                      _pendingHtml = null;
                    }
                  },
                ),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(
                        color: AppColor.authButton),
                  ),
              ],
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColor.authButton),
            const SizedBox(height: 12),
            AppText(
              _error,
              fontSize: FontSizes.small,
              color: AppColor.grey,
              align: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchPage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColor.authButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AppText(
                  'Try Again',
                  fontSize: FontSizes.regular,
                  fontWeight: FontWeights.semiBold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
