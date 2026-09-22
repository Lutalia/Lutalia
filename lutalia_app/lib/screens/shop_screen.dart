import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(
        Uri.parse("https://lutalia.myshopify.com/collections/all"),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5EFE6),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Lutalia Shop",
          style: TextStyle(
            fontFamily: "NewFirst",
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD49A84),
          ),
        ),
      ),

      body: Stack(
        children: [
          WebViewWidget(controller: controller),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFD49A84),
              ),
            ),
        ],
      ),
    );
  }
}
