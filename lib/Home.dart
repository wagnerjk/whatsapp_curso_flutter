import 'package:flutter/material.dart';
import 'package:whatsapp/Login.dart';
import 'package:whatsapp/telas/AbaContatos2.dart';
import 'package:whatsapp/telas/AbaConversas.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import 'RouteGenerator.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {

  TabController _tabController;
  List<String> itensMenu = [
    "Configurações", "Deslogar"
  ];

  @override
  void initState() {
    super.initState();

    User user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((User usr) {
      user = usr;
      if (user == null){
        Navigator.pushReplacementNamed(context, RouteGenerator.ROTA_LOGIN);
      }
    });

    _tabController = TabController(
        length: 2,
        vsync: this
    );
  }

  _escolhaMenuItem(String itemEscolhido){

    switch(itemEscolhido){
      case "Configurações":
        Navigator.pushNamed(context, RouteGenerator.ROTA_CONFIG);
        break;
      case "Deslogar":
        _deslogarUsuario();
        break;
    }
  }

  _deslogarUsuario() async {

    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.signOut();

    Navigator.pushReplacementNamed(context, RouteGenerator.ROTA_LOGIN);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("WhatsApp"),
        elevation: Platform.isIOS ? 0 : 4,
        bottom: TabBar(
          indicatorWeight: 4,
          labelStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold
          ),
          controller: _tabController,
          indicatorColor: Platform.isIOS ? Colors.grey[400] : Colors.white,
          tabs: <Widget>[
            Tab(text: "Conversas",),
            Tab(text: "Contatos",),
          ],
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: _escolhaMenuItem,
            itemBuilder: (context){
              return itensMenu.map((String item) {
                return PopupMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList();
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          AbaConversas(),
          AbaContatos2()
        ],
      ),
    );
  }
}
