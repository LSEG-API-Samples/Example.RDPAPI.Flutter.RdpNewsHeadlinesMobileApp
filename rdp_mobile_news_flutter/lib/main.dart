import 'package:flutter/material.dart';
import 'package:rdp_mobile_news_flutter/pages/rdp_login_page.dart';

void main() => runApp(RdpMobileApp());

class RdpMobileApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RDP Login',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
