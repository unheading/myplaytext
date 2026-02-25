import 'dart:ui';

import 'package:app/pages/category/controller.dart';
import 'package:app/pages/category/index.dart';
import 'package:app/pages/home/index.dart';
import 'package:app/pages/my/index.dart';
import 'package:app/pages/ranking/index.dart';
import 'package:app/pages/weekly/index.dart';
import 'package:flutter/material.dart';

class mainpage extends StatefulWidget {
  mainpage({Key? key}) : super(key: key);

  @override
  _mainpageState createState() => _mainpageState();
}

class _mainpageState extends State<mainpage> {
  final CategoryViewController _categoryController = CategoryViewController();
  final List<Map<String,String>> _tabList=[
    {    
      "icon":"lib/assets/sleep__home.png",
      "active_icon":"lib/assets/home.png",
      "text":"主页"
    },
        {
      "icon":"lib/assets/sleep__planet.png",
      "active_icon":"lib/assets/planet-line.png",
      "text":"分类"
    },
        {
      "icon":"lib/assets/sleep__ranking.png",
      "active_icon":"lib/assets/ranking.png",
      "text":"排行榜"
    },
        {
      "icon":"lib/assets/sleep_schedule.png",
      "active_icon":"lib/assets/schedule.png",
      "text":"周表"
    },
        {
      "icon":"lib/assets/sleep__person-16.png",
      "active_icon":"lib/assets/person-16.png",
      "text":"我的"
    },
  ];
  int _currentIndex=0;
  List<BottomNavigationBarItem> _getTabBarWiget(){
    return List.generate(_tabList.length, (int index){
      return BottomNavigationBarItem(
        icon: Image.asset(_tabList[index]["icon"]!,
          width: 40,height: 40,
        ),
        activeIcon: Image.asset(_tabList[index]["active_icon"]!,
          width: 40,height: 40,
        ),
        label: _tabList[index]["text"]
        );
        
    });
  }
  List<Widget> _getChildrenBody(){
    return [
      homeView(
        onOpenCategory: (typeId) {
          _categoryController.openType(typeId);
          if (_currentIndex == 1) return;
          setState(() => _currentIndex = 1);
        },
      ),
      categoryView(controller: _categoryController),
      rankingView(),
      weeklyView(),
      myView()
    ];
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color.fromARGB(255, 18, 18, 18),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _getChildrenBody(),
        ),
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(90, 18, 18, 18),
              border: Border(
                top: BorderSide(
                  color: Color.fromARGB(28, 255, 255, 255),
                  width: 1,
                ),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashFactory: NoSplash.splashFactory,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                enableFeedback: false,
                selectedLabelStyle: const TextStyle(fontSize: 15, height: 0),
                unselectedLabelStyle: const TextStyle(fontSize: 15, height: 0),
                showUnselectedLabels: true,
                unselectedItemColor: const Color.fromARGB(160, 255, 255, 255),
                selectedItemColor: const Color.fromARGB(255, 255, 128, 128),
                onTap: (int index) {
                  _currentIndex = index;
                  setState(() {});
                },
                currentIndex: _currentIndex,
                items: _getTabBarWiget(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
