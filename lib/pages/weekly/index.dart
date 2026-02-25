import 'package:flutter/cupertino.dart';

class weeklyView extends StatefulWidget {
  weeklyView({Key? key}) : super(key: key);

  @override
  _weeklyViewState createState() => _weeklyViewState();
}

class _weeklyViewState extends State<weeklyView> {
  @override
  Widget build(BuildContext context) {
    return Center(
       child: Text("周表"),
    );
  }
}