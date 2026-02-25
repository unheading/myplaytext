import 'package:flutter/cupertino.dart';

class myView extends StatefulWidget {
  myView({Key? key}) : super(key: key);

  @override
  _myViewState createState() => _myViewState();
}

class _myViewState extends State<myView> {
  @override
  Widget build(BuildContext context) {
    return Center(
       child: Text("我的"),
    );
  }
}
