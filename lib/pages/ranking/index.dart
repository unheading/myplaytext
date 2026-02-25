import 'package:flutter/cupertino.dart';

class rankingView extends StatefulWidget {
  rankingView({Key? key}) : super(key: key);

  @override
  _rankingViewState createState() => _rankingViewState();
}

class _rankingViewState extends State<rankingView> {
  @override
  Widget build(BuildContext context) {
    return Center(
       child: Text("排行榜"),
    );
  }
}