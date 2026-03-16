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

  late InAppWebViewController _webViewController;

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
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
          ),
        ),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        onLoadStart: (controller, url) {
          if (url != null) {
            final urlStr = url.toString();

            if (urlStr.contains('flutter-payment-success')) {
              context.pop(true); // return success
            }
            else if (urlStr.contains('flutter-payment-cancel')) {
              context.pop(false); // return cancel
            }
          }
        },
      ),
    );
  }
}