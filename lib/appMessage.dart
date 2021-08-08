
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vin_chat/chat_page.dart';
import 'package:vin_chat/services/database.dart';

import 'helper.dart';

class MessageList extends StatefulWidget {
  final String chatRoomId;

  const MessageList({Key? key,required this.chatRoomId}) : super(key: key);

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  ScrollController _scrollController = ScrollController();
  TextEditingController messageEditingController = new TextEditingController();
  bool loadingDoc=true;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {

      if (_scrollController.offset >=
          (_scrollController.position.maxScrollExtent) &&
          !_scrollController.position.outOfRange) {
        print("calling this ************");

        _getChats();
      }
    });
  }

  final StreamController<List<DocumentSnapshot>> _chatController =
  StreamController<List<DocumentSnapshot>>.broadcast();

  List<List<DocumentSnapshot>> _allPagedResults = [<DocumentSnapshot>[]];

  static const int chatLimit = 10;
  DocumentSnapshot? _lastDocument;
  bool _hasMoreData = true;

  Stream<List<DocumentSnapshot>> listenToChatsRealTime() {
    _getChats();
    return _chatController.stream;
  }

  void _getChats() {
    final CollectionReference _chatCollectionReference = FirebaseFirestore
        .instance
        .collection('chatRoom')
        .doc(widget.chatRoomId)
        .collection("chats");
    var pagechatQuery = _chatCollectionReference
        .orderBy('time', descending: true)
        .limit(chatLimit);

    if (_lastDocument != null) {
      pagechatQuery = pagechatQuery.startAfterDocument(_lastDocument!);
    }

    if (!_hasMoreData) return;

    var currentRequestIndex = _allPagedResults.length;
    pagechatQuery.snapshots().listen(
          (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          var generalChats = snapshot.docs.toList();

          var pageExists = currentRequestIndex < _allPagedResults.length;

          if (pageExists) {
            _allPagedResults[currentRequestIndex] = generalChats;
          } else {
            _allPagedResults.add(generalChats);
          }

          var allChats = _allPagedResults.fold<List<DocumentSnapshot>>(
              <DocumentSnapshot>[],
                  (initialValue, pageItems) => initialValue..addAll(pageItems));

          _chatController.add(allChats);

          if (currentRequestIndex == _allPagedResults.length - 1) {
            _lastDocument = snapshot.docs.last;
          }

          _hasMoreData = generalChats.length == chatLimit;
        }
      },

    );

    setState(() {
      loadingDoc=false;
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
      backgroundColor: Colors.deepPurpleAccent,
      body: Stack(
        children: [
          // (loadingDoc) ? Container(height: 30,child: Align(alignment: Alignment.center,child: CircularProgressIndicator())) : Container(),

          Container(
            padding: const EdgeInsets.only(bottom:60.0),
            child: StreamBuilder<List<DocumentSnapshot>>(
                stream: listenToChatsRealTime(),
                builder: (ctx, chatSnapshot) {
                  if (chatSnapshot.connectionState == ConnectionState.waiting ||
                      chatSnapshot.connectionState == ConnectionState.none) {
                    return chatSnapshot.hasData
                        ? Center(
                      child: CircularProgressIndicator(),
                    )
                        : Center(
                      child: Text("Start a Conversation."),
                    );
                  } else {
                    if (chatSnapshot.hasData) {
                      final chatDocs = chatSnapshot.data!;
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        itemBuilder: (ctx, i) {
                          Map chatData = chatDocs[i].data() as Map;
                          return MessageTile(
                            message: chatSnapshot.data![i].get('message'),
                            sendByMe: Helper.sender == chatSnapshot.data![i].get('sendBy'),
                          );
                        },
                        itemCount: chatDocs.length,
                      );
                    } else {
                      return CircularProgressIndicator();
                    }
                  }
                }),
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
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
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

        ],
      ),
    );
  }
}
