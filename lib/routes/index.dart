//管理路由
import 'package:app/pages/login/index.dart';
import 'package:app/pages/main/index.dart';
import 'package:flutter/material.dart';

Widget getRootWiget(){
  return MaterialApp(
    //命名路由
    routes: getRootRoutes(),

  );
}

Map<String, Widget Function(BuildContext)> getRootRoutes(){
  return{
    "/":(context)=>mainpage(),//主页
    "/login":(context)=>loginpage(),//登录页
  };
}
