import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

class CustomWebView extends StatefulWidget {
  final String checkoutUrl;
  final String title;

  const CustomWebView({
    super.key,
    required this.checkoutUrl,
    required this.title,
  });

  @override
  State<CustomWebView> createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  bool _handledResult = false;

  void _finish(bool success) {
    if (_handledResult || !mounted) return;
    _handledResult = true;
    context.pop(success);


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(widget.checkoutUrl),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
        ),
        onLoadStart: (controller, url) {
          if (url != null) {
            final urlStr = url.toString();

            if (urlStr.contains('flutter-payment-success')) {
              _finish(true);
            } else if (urlStr.contains('flutter-payment-cancel')) {
              _finish(false);
            }
          }
        },
      ),
    );
  }
}
