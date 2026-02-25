import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Hmrm extends StatefulWidget {
  Hmrm({Key? key}) : super(key: key);

  @override
  _HmrmState createState() => _HmrmState();
}

class _HmrmState extends State<Hmrm> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "日漫 🔥🔥🔥",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(14),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: Color(0xFF63D2A3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                alignment: Alignment.center,
                width: 160,
                height: 200,
                margin: EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  "日漫$index",
                  style: TextStyle(color: Colors.white),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}