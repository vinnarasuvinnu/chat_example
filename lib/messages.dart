
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vin_chat/chat_page.dart';
import 'package:vin_chat/helper.dart';
import 'package:vin_chat/services/database.dart';

class MessagePages extends StatefulWidget {
  final String chatRoomId;

  const MessagePages({Key? key,required this.chatRoomId}) : super(key: key);

  @override
  _MessagePagesState createState() => _MessagePagesState();
}

class _MessagePagesState extends State<MessagePages> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> products = [];
  bool isLoading = false;
  bool hasMore = true;
  int documentLimit = 10;
  int queryIndex=0;
  late DocumentSnapshot lastDocument;
  ScrollController _scrollController = ScrollController();

  StreamController<List<DocumentSnapshot>> _controller =
  StreamController<List<DocumentSnapshot>>();

  Stream<List<DocumentSnapshot>> get _streamController => _controller.stream;
  TextEditingController messageEditingController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    getProducts();
    _scrollController.addListener(() {
      double maxScroll = _scrollController.position.minScrollExtent;
      double currentScroll = _scrollController.position.pixels;
      double delta = MediaQuery.of(context).size.height * 0.20;
      if (maxScroll - currentScroll <= delta) {
        getProducts();
      }
    });
  }

  getProducts() async {
    if (!hasMore) {
      print('No More Products');
      return;
    }
    if (isLoading) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    QuerySnapshot querySnapshot;
    if (queryIndex==0) {
      querySnapshot = await firestore
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection("chats")
          .orderBy('time',descending: true).limit(Helper.pageLimit)
          .get();
    } else {
      querySnapshot = await firestore
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection("chats")
          .orderBy('time',descending: true).startAfterDocument(lastDocument).limit(Helper.pageLimit)
          .get();

    }

    setState(() {
      queryIndex=queryIndex+1;
    });
    if (querySnapshot.docs.length < documentLimit) {
      hasMore = false;
    }

    lastDocument = querySnapshot.docs[querySnapshot.docs.length - 1];

    products.addAll(querySnapshot.docs);
    _controller.sink.add(products);

    setState(() {
      isLoading = false;
    });
  }

  addMessage() {
    if (messageEditingController.text.isNotEmpty) {
      Map<String, dynamic> chatMessageMap = {
        "sendBy": Helper.sender,
        "message": messageEditingController.text,
        'time': DateTime
            .now()
            .millisecondsSinceEpoch,
      };

      DatabaseMethods().addMessage(widget.chatRoomId, chatMessageMap);


      setState(() {
        messageEditingController.text = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Pagination with Firestore'),
      ),
      body: Stack(children: [

        isLoading
            ? Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(5),
          color: Colors.yellowAccent,
          child: Text(
            'Loading',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        )
            : Container(),
        Padding(
          padding: const EdgeInsets.only(bottom:50.0),

          child: StreamBuilder<List<DocumentSnapshot>>(
            stream: _streamController,
            builder: (sContext, snapshot) {
              if (snapshot.hasData && snapshot.data!.length > 0) {
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: snapshot.data!.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    return MessageTile(
                      message: snapshot.data![index].get('message'),
                      sendByMe: Helper.sender == snapshot.data![index].get('sendBy'),
                    );
                  },
                );
              } else {
                return Center(
                  child: Text('No Data...'),
                );
              }
            },
          ),
        ),
        Container(alignment: Alignment.bottomCenter,
          width: MediaQuery
              .of(context)
              .size
              .width,
          child: Container(
            color: Colors.grey,
            child: Row(
              children: [
                Expanded(
                    child: TextField(

                      controller: messageEditingController,
                      decoration: InputDecoration(
                          hintText: "Message ...",
                          hintStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          border: InputBorder.none
                      ),
                    )),
                SizedBox(width: 16,),
                GestureDetector(
                  onTap: () {
                    addMessage();
                  },
                  child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(



                          borderRadius: BorderRadius.circular(40)
                      ),
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.send)

                  ),
                ),
              ],
            ),
          ),
        ),

      ]),
    );
  }
}
