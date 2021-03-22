import 'package:flutter/material.dart';
import 'package:whatsapp/Cadastro.dart';
import 'package:whatsapp/Configuracoes.dart';
import 'package:whatsapp/Home.dart';
import 'package:whatsapp/Login.dart';
import 'package:whatsapp/Mensagem.dart';

class RouteGenerator{

  static const String ROTA_LOGIN = "/login";
  static const String ROTA_CADASTRO = "/cadastro";
  static const String ROTA_HOME = "/home";
  static const String ROTA_CONFIG = "/configuracoes";
  static const String ROTA_MENSAGEM  = "/mensagem";

  static Route<dynamic> generateRoute(RouteSettings settings){

    final args = settings.arguments;

    switch(settings.name){
      case "/" :
        return MaterialPageRoute(
          builder: (_) => Login()
        );
      case ROTA_LOGIN :
        return MaterialPageRoute(
            builder: (_) => Login()
        );
      case ROTA_CADASTRO :
        return MaterialPageRoute(
            builder: (_) => Cadastro()
        );
      case ROTA_HOME :
        return MaterialPageRoute(
            builder: (_) => Home()
        );
      case ROTA_CONFIG :
        return MaterialPageRoute(
            builder: (_) => Configuracoes()
        );
      case ROTA_MENSAGEM :
        return MaterialPageRoute(
            builder: (_) => Mensagem(args)
        );
      default:
        _erroRota();
    }

  }

  static Route<dynamic> _erroRota(){
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: Text("Tela não encontrada!"),),
          body: Center(
            child: Text("Tela não encontrada!"),
          ),
        );
      }
    );
  }

}