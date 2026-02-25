import 'package:flutter/material.dart';

class loginpage extends StatefulWidget {
  loginpage({Key? key}) : super(key: key);

  @override
  _loginpageState createState() => _loginpageState();
}

class _loginpageState extends State<loginpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("登录"),),
      body: Center(child: Text("登录页面"),),
    );
  }
}