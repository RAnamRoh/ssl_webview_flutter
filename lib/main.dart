import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSLCommerz Integration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isPremiumUser = false;
  bool showWebView = false;
  late String paymentUrl; // Changed to non-nullable
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains("success.html")) {
              // Payment was successful
              setState(() {
                isPremiumUser = true;
                showWebView = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Payment successful! You are now a premium user.")),
              );
              return NavigationDecision.prevent;
            } else if (request.url.contains("fail.html") || request.url.contains("cancel.html")) {
              // Payment failed or was canceled
              setState(() {
                showWebView = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Payment unsuccessful. Please try again.")),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> initiatePaymentSession() async {
    const String storeId = "brain6728ccd1bbe64"; // Replace with your actual store ID
    const String storePassword = "brain6728ccd1bbe64@ssl"; // Replace with your actual store password

    final url = Uri.parse("https://sandbox.sslcommerz.com/gwprocess/v4/api.php");

    // Prepare the body parameters for the request
    final body = {
      "store_id": storeId,
      "store_passwd": storePassword,
      "total_amount": "10.0",
      "currency": "BDT",
      "tran_id": "unique_transaction_id_${DateTime.now().millisecondsSinceEpoch}", // Unique transaction ID
      "success_url": "https://sandbox.sslcommerz.com/EasyCheckout/success.html",
      "fail_url": "https://sandbox.sslcommerz.com/fail",
      "cancel_url": "https://sandbox.sslcommerz.com/cancel",
      "cus_name": "Customer Name",
      "cus_email": "customer@example.com",
      "cus_phone": "0123456789",
      "product_category": "Subscription",
      "shipping_method": "NO",
      "num_of_item": "1",
      "product_name": "Premium Subscription",
      "product_profile": "general",
      "cus_add1": "Dhaka",
      "cus_city": "Dhaka",
      "cus_country": "Bangladesh", // Update this if needed
    };

    // Make the POST request with x-www-form-urlencoded
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body.map((key, value) => MapEntry(key, value.toString())),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'SUCCESS') {
          String sessionKey = data['sessionkey'];
          String gateWayURL = "${data["GatewayPageURL"]}";
          String paymentUrl = gateWayURL;
          String testURL = "https://sandbox.sslcommerz.com/EasyCheckout/$sessionKey";
          setState(() {
            this.paymentUrl = gateWayURL; // Store payment URL
            showWebView = true;
          });
          _controller.loadRequest(Uri.parse(paymentUrl));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to create payment session: ${data['failedreason']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to initiate payment session")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("SSLCommerz Payment"),
      ),
      body: showWebView
          ? WebViewWidget(
        controller: _controller,
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "This is a basic SSLCommerz integration example.",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isPremiumUser ? null : initiatePaymentSession,
              child: Text(isPremiumUser ? "You are a Premium User" : "Buy Premium"),
            ),
          ],
        ),
      ),
    );
  }
}
