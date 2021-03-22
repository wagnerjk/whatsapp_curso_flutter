import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp/Home.dart';
import 'package:whatsapp/Login.dart';
import 'package:whatsapp/RouteGenerator.dart';
import 'dart:io';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final ThemeData temaIos = ThemeData(
      primaryColor: Colors.grey[200],
      accentColor: Color(0xff25D366)
  );

  final ThemeData temaPadrao = ThemeData(
      primaryColor: Color(0xff075E54),
      accentColor: Color(0xff25D366)
  );

  runApp(MaterialApp(
    home: Login(),
    theme: Platform.isIOS ? temaIos : temaPadrao,
    initialRoute: "/",
    onGenerateRoute: RouteGenerator.generateRoute,
    debugShowCheckedModeBanner: false,
  ));
}
