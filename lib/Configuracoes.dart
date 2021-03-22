import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class Configuracoes extends StatefulWidget {
  @override
  _ConfiguracoesState createState() => _ConfiguracoesState();
}

class _ConfiguracoesState extends State<Configuracoes> {

  TextEditingController _controllerNome = TextEditingController();
  File _image;
  String _idUsuarioLogado;
  String _urlImagemRecuperada;
  bool _subindoImagem = false;

  Future _recuperarImagem(String origemImagem) async {
    final imagePicker = ImagePicker();
    PickedFile imageSelec;

    if(origemImagem == "camera"){
      imageSelec = await imagePicker.getImage(source: ImageSource.camera);
    } else{
      imageSelec = await imagePicker.getImage(source: ImageSource.gallery);
    }

    setState(() {
      _image = File(imageSelec.path);
      if(_image != null){
        _subindoImagem = true;
        _uploadImagem();
      }
    });
  }

  Future _uploadImagem() async {

    FirebaseStorage storage = FirebaseStorage.instance;
    Reference pastaRaiz = storage.ref();
    Reference arquivo = pastaRaiz
        .child("Perfil")
        .child(_idUsuarioLogado + ".jpg");

    UploadTask task = arquivo.putFile(_image);

    task.snapshotEvents.listen((TaskSnapshot snapshot) {
      if(snapshot.state == TaskState.running){
        setState(() {
          _subindoImagem = true;
        });
      } else if(snapshot.state == TaskState.success){
        setState(() {
          _subindoImagem = false;
        });
      }
    });

    String url = await (await task).ref.getDownloadURL();
    _atualizarUrlImagemFirestore(url);

    setState(() {
      _urlImagemRecuperada = url;
    });
  }

  _atualizarNomeFirebase(){

    String nome = _controllerNome.text;
    FirebaseFirestore db = FirebaseFirestore.instance;

    Map<String, dynamic> dadosAtualizar = {
      "nome" : nome
    };

    db.collection("usuarios")
        .doc(_idUsuarioLogado)
        .update(dadosAtualizar);
  }

  _atualizarUrlImagemFirestore(String url){

    FirebaseFirestore db = FirebaseFirestore.instance;

    Map<String, dynamic> dadosAtualizar = {
      "urlImagem" : url
    };

    db.collection("usuarios")
      .doc(_idUsuarioLogado)
      .update(dadosAtualizar);
  }

  _recurarDadosUsuario() async {
    User user = FirebaseAuth.instance.currentUser;
    _idUsuarioLogado = user.uid;

    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentSnapshot snapshot = await db.collection("usuarios")
        .doc(_idUsuarioLogado)
        .get();

    Map<String, dynamic> dados = snapshot.data();
    _controllerNome.text = dados["nome"];

    if(dados["urlImagem"] != null){
      setState(() {
        _urlImagemRecuperada = dados["urlImagem"];
      });


    }
  }

  @override
  void initState() {
    super.initState();
    _recurarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Configurações"),),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16),
                  child: _subindoImagem
                      ? CircularProgressIndicator()
                      : Container(),
                ),
                CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.grey,
                  backgroundImage:
                  _urlImagemRecuperada != null
                    ? NetworkImage(_urlImagemRecuperada)
                    : null
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    FlatButton(
                      child: Text("Câmera"),
                      onPressed: (){
                        _recuperarImagem("camera");
                      },
                    ),
                    FlatButton(
                      child: Text("Galeria"),
                      onPressed: (){
                        _recuperarImagem("galeria");
                      },
                    )
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _controllerNome,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(fontSize: 20),
                    decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                        hintText: "Nome",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32))),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 10),
                  child: RaisedButton(
                    child: Text(
                      "Salvar",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    color: Colors.green,
                    padding: EdgeInsets.fromLTRB(32, 16, 32, 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32)),
                    onPressed: () {
                      _atualizarNomeFirebase();
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
