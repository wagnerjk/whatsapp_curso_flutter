import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp/model/Conversa.dart';
import 'package:whatsapp/model/Usuario.dart';

import '../RouteGenerator.dart';

class AbaConversas extends StatefulWidget {
  @override
  _AbaConversasState createState() => _AbaConversasState();
}

class _AbaConversasState extends State<AbaConversas> {

  final _controller = StreamController<QuerySnapshot>.broadcast();
  FirebaseFirestore db = FirebaseFirestore.instance;
  String _idUsuarioLogado;

  Stream<QuerySnapshot> _adicionarListenerConversas(){

    final stream = db.collection("conversas")
                      .doc(_idUsuarioLogado)
                      .collection("ultima_conversa")
                      .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
    });

  }

  Future<QuerySnapshot> _adicionarConversas(){

    final stream = db.collection("conversas")
        .doc(_idUsuarioLogado)
        .collection("ultima_conversa")
        .get().asStream();

    setState(() {
      stream.listen((dados) {
        _controller.add(dados);
      });
    });

  }

  _recurarDadosUsuario() async {
    User user = FirebaseAuth.instance.currentUser;
    _idUsuarioLogado = user.uid;

    //_adicionarListenerConversas();
  }

  @override
  void initState() {
    super.initState();
    _recurarDadosUsuario();
    //_adicionarListenerConversas();
    _adicionarConversas();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.close();
  }

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<QuerySnapshot>(
      stream: _controller.stream,
      // ignore: missing_return
      builder: (context, snapshot) {
        switch (snapshot.connectionState){
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
              child: Column(
                children: <Widget>[
                  Text("Carregando conversas"),
                  CircularProgressIndicator()
                ],
              ),
            );
            break;
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError){
              return Text("Erro ao carregar dados!");
            } else {
              QuerySnapshot querySnapshot = snapshot.data;
              if (querySnapshot.docs.length == 0){
                return Center(
                  child: Text(
                    "Você não tem nenhuma mensagem ainda...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                );
              }

              return ListView.builder(
                  itemCount: querySnapshot.docs.length,
                  itemBuilder: (context, index) {

                    List<DocumentSnapshot> conversas = querySnapshot.docs.toList();
                    DocumentSnapshot item = conversas[index];

                    String urlImagem      = item["caminhoFoto"];
                    String tipo           = item["tipoMensagem"];
                    String mensagem       = item["mensagem"];
                    String nome           = item["nome"];
                    String idDestinatario = item["idDestinatario"];

                    Usuario usuario = Usuario();
                    usuario.nome = nome;
                    usuario.urlImagem = urlImagem;
                    usuario.idUsuario = idDestinatario;

                    return ListTile(
                      onTap: () {
                        Navigator.pushNamed(
                            context,
                            RouteGenerator.ROTA_MENSAGEM,
                            arguments: usuario
                        );
                      },
                      contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      leading: CircleAvatar(
                        maxRadius: 30,
                        backgroundColor: Colors.grey,
                        backgroundImage: urlImagem != null
                            ? NetworkImage(urlImagem)
                            : null,
                      ),
                      title: Text(
                        nome,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                        ),
                      ),
                      subtitle: Text(
                          tipo == "texto"
                              ? mensagem
                              : "[Imagem]",
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14
                        ),
                      ),
                    );
                  });
            }
        }
      },
    );
  }
}
