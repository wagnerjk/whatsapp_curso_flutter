import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:whatsapp/model/Conversa.dart';
import 'package:whatsapp/model/Message.dart';
import 'package:whatsapp/model/Usuario.dart';

class Mensagem extends StatefulWidget {
  Usuario contato;

  Mensagem(this.contato);

  @override
  _MensagemState createState() => _MensagemState();
}

class _MensagemState extends State<Mensagem> {
  String _idUsuarioLogado;
  String _idUsuarioDestinatario;
  FirebaseFirestore db = FirebaseFirestore.instance;
  TextEditingController _controllerMensagem = TextEditingController();
  bool _subindoImagem = false;
  File _image;
  final _controller = StreamController<QuerySnapshot>.broadcast();
  ScrollController _scrollController = ScrollController();

  _enviarMensagem() {
    String textoMensagem = _controllerMensagem.text;
    if (textoMensagem.isNotEmpty) {
      Message message = Message();
      message.idUsuario = _idUsuarioLogado;
      message.mensagem = textoMensagem;
      message.urlImagem = "";
      message.data = Timestamp.now().toString();
      message.tipo = "texto";

      // salva para remetente
      _salvarMensagem(_idUsuarioLogado, _idUsuarioDestinatario, message);
      // salva para destinatário
      _salvarMensagem(_idUsuarioDestinatario, _idUsuarioLogado, message);

      //_controllerMensagem.clear();
      _controllerMensagem.value = TextEditingValue(selection: TextSelection.collapsed(offset:0));
      _salvarConversa(message);
    }
  }

  _salvarConversa(Message msg){

    Conversa cRemetente = Conversa();
    cRemetente.idRemetente = _idUsuarioLogado;
    cRemetente.idDestinatario = _idUsuarioDestinatario;
    cRemetente.mensagem = msg.mensagem;
    cRemetente.nome = widget.contato.nome;
    cRemetente.caminhoFoto = widget.contato.urlImagem;
    cRemetente.tipoMensagem = msg.tipo;
    cRemetente.salvar();

    Conversa cDestinatario = Conversa();
    cDestinatario.idRemetente = _idUsuarioDestinatario;
    cDestinatario.idDestinatario = _idUsuarioLogado;
    cDestinatario.mensagem = msg.mensagem;
    cDestinatario.nome = widget.contato.nome;
    cDestinatario.caminhoFoto = widget.contato.urlImagem;
    cDestinatario.tipoMensagem = msg.tipo;
    cDestinatario.salvar();
  }

  _salvarMensagem(
      String idRemetente, String idDestinatario, Message msg) async {
    await db
        .collection('mensagens')
        .doc(idRemetente)
        .collection(idDestinatario)
        .add(msg.toMap());
  }

  _enviarFoto(String origemImagem) async {

    final imagePicker = ImagePicker();
    PickedFile imageSelec;

    if(origemImagem == "camera"){
      imageSelec = await imagePicker.getImage(source: ImageSource.camera);
    } else{
      imageSelec = await imagePicker.getImage(source: ImageSource.gallery);
    }

    setState(() async {
      _image = File(imageSelec.path);
      if(_image != null){
        _subindoImagem = true;
        _uploadImagem();
      }
    });
  }

  Future _uploadImagem() async{

    String nomeImagem = DateTime.now().millisecondsSinceEpoch.toString();
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference pastaRaiz = storage.ref();
    Reference arquivo = pastaRaiz
        .child("mensagens")
        .child(_idUsuarioLogado)
        .child(nomeImagem + ".jpg");

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

    Message message = Message();
    message.idUsuario = _idUsuarioLogado;
    message.mensagem = "";
    message.urlImagem = url;
    message.data = Timestamp.now().toString();
    message.tipo = "imagem";

    // salva para remetente
    _salvarMensagem(_idUsuarioLogado, _idUsuarioDestinatario, message);
    // salva para destinatário
    _salvarMensagem(_idUsuarioDestinatario, _idUsuarioLogado, message);

  }

  _recurarDadosUsuario() async {
    User user = FirebaseAuth.instance.currentUser;
    _idUsuarioLogado = user.uid;

    _idUsuarioDestinatario = widget.contato.idUsuario;

    _adicionarListenerMensagens();
  }

  Stream<QuerySnapshot> _adicionarListenerMensagens(){

    final stream = db.collection('mensagens')
        .doc(_idUsuarioLogado)
        .collection(_idUsuarioDestinatario)
        .orderBy("data", descending: false)
        .snapshots();

    stream.listen((dados) {
      _controller.add(dados);
      Timer(Duration(seconds: 1), () {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });

  }

  @override
  void initState() {
    super.initState();
    _recurarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {

    var caixaMensagem = Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: TextField(
                maxLines: 4,
                minLines: 1,
                controller: _controllerMensagem,
                autofocus: true,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 20),
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 8, 32, 8),
                    hintText: "Digite uma mensagem...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(32)),
                    prefixIcon:
                      _subindoImagem
                        ? CircularProgressIndicator()
                        : IconButton(
                          icon: Icon(Icons.camera_alt),
                          onPressed: () {
                            return showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  content: Text("Selecionar imagem da..."),
                                  title: Text("Enviar imagem"),
                                  actions: <Widget>[
                                    FlatButton(
                                      child: Text("Câmera"),
                                      onPressed: () {
                                        _enviarFoto("camera");
                                        Navigator.pop(context);
                                      },
                                    ),
                                    FlatButton(
                                      child: Text("Galeria"),
                                      onPressed: () {
                                        _enviarFoto("galeria");
                                        Navigator.pop(context);
                                      },
                                    )
                                  ],
                                );
                              }
                            );
                          },
                        )
                ),
              ),
            ),
          ),
          Platform.isIOS
            ? CupertinoButton(
                child: Text("Enviar"),
                onPressed: _enviarMensagem,
          )
            : FloatingActionButton(
                backgroundColor: Color(0xff075E54),
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                ),
                mini: true,
                onPressed: _enviarMensagem,
              )
        ],
      ),
    );

    var stream = StreamBuilder(
      stream: _controller.stream,
      // ignore: missing_return
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
            return Center(
              child: Column(
                children: <Widget>[
                  Text("Carregando mensagens"),
                  CircularProgressIndicator()
                ],
              ),
            );
            break;
          case ConnectionState.active:
          case ConnectionState.done:
            QuerySnapshot querySnapshot = snapshot.data;

            if (snapshot.hasError) {
              return Text("Erro ao carregar dados!");
            } else {
              return Expanded(
                child: ListView.builder(
                    controller: _scrollController,
                    itemCount: querySnapshot.docs.length,
                    itemBuilder: (context, index) {

                      List<DocumentSnapshot> mensagens = querySnapshot.docs.toList();
                      DocumentSnapshot item = mensagens[index];

                      double larguraContainer =
                          MediaQuery.of(context).size.width * 0.8;

                      Alignment alinhamento = Alignment.centerRight;
                      Color cor = Color(0xffd2ffa5);
                      if (_idUsuarioLogado != item["idUsuario"]) {
                        cor = Colors.white;
                        alinhamento = Alignment.bottomLeft;
                      }

                      return Align(
                        alignment: alinhamento,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Container(
                            width: larguraContainer,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: cor,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8))),
                            child: item["tipo"] == "texto"
                                      ? Text(item["mensagem"], style: TextStyle(fontSize: 18),)
                                      : Image.network(item["urlImagem"])
                          ),
                        ),
                      );
                    }),
              );
            }
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        title: Row(
          children: <Widget>[
            CircleAvatar(
                maxRadius: 20,
                backgroundColor: Colors.grey,
                backgroundImage: widget.contato.urlImagem != null
                    ? NetworkImage(widget.contato.urlImagem)
                    : null),
            Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text(widget.contato.nome),
            )
          ],
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("assets/images/bg.png"), fit: BoxFit.cover)),
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.all(8),
            child: Column(
              children: <Widget>[stream, caixaMensagem],
            ),
          ),
        ),
      ),
    );
  }
}