
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vin_chat/helper.dart';
import 'package:vin_chat/services/database.dart';
import 'package:image_picker/image_picker.dart';

class ChateScreen extends StatefulWidget {
  final String chatRoomId;

  const ChateScreen({Key? key,required this.chatRoomId}) : super(key: key);

  @override
  _ChateScreenState createState() => _ChateScreenState();
}

class _ChateScreenState extends State<ChateScreen> {
  final ImagePicker _picker = ImagePicker();
  bool loadingDoc=true;
  bool chatsReceived=false;
  late List<DocumentSnapshot> paginationAfter;
  ScrollController controller = ScrollController();
  bool hasMore = true; // flag for more products available or not
  bool isLoading = false; // track if products fetching
  late DocumentSnapshot lastDocument; // flag for last document from where next 10 records to be fetched

  StreamController<List<DocumentSnapshot>> _streamController =
  StreamController<List<DocumentSnapshot>>();
  List<DocumentSnapshot> _products = [];
  late Stream<QuerySnapshot> chats;
  TextEditingController messageEditingController = new TextEditingController();



  Widget chatMessages(){
    return (chatsReceived) ? Container(
      child: StreamBuilder <QuerySnapshot>(
        stream: chats,
        builder: (context, snapshot){
          return snapshot.hasData ?  ListView.builder(
              itemCount: snapshot.data!.docs.length,
              reverse: true,
              controller: controller,
              itemBuilder: (context, index){
                return index >= snapshot.data!.docs.length ? CircularProgressIndicator() :  MessageTile(
                  message: snapshot.data!.docs[index].get('message'),
                  sendByMe: Helper.sender == snapshot.data!.docs[index].get('sendBy'),
                );
              }) : Container();
        },
      ),
    ) : Container();
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
  getImageData()async{
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

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
    if (lastDocument == null) {
      querySnapshot = await DatabaseMethods().getChats(widget.chatRoomId);
    } else {
      querySnapshot = await DatabaseMethods().getChatsPagination(widget.chatRoomId, lastDocument);
      print(1);
    }
    if (querySnapshot.docs.length < Helper.pageLimit) {
      hasMore = false;
    }
    lastDocument = querySnapshot.docs[querySnapshot.docs.length - 1];
    setState(() {
      isLoading = false;
    });
  }

  void _scrollListener() {
    if (controller.offset >= controller.position.minScrollExtent &&
        !controller.position.outOfRange) {
      print("at the top of list");
    }
  }

  @override
  void initState() {
    print("gettings chat room id********************");
    print(widget.chatRoomId);
    openChatList();



    super.initState();
  }

  openChatList()async{
    controller.addListener(_scrollListener);
    DatabaseMethods().getChats(widget.chatRoomId).then((val) async {

      setState(() {
        chats = val;
        loadingDoc=false;

        chatsReceived=true;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat"),),
      body: Stack(
        children: [
          (loadingDoc) ? Container(height: 30,child: Align(alignment: Alignment.center,child: CircularProgressIndicator())) : Container(),
          Padding(
            padding: const EdgeInsets.only(bottom:50.0),
            child: chatMessages(),
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
        ],
      ),
    );
  }
}


class MessageTile extends StatelessWidget {
  final String message;
  final bool sendByMe;

  MessageTile({required this.message, required this.sendByMe});


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: sendByMe ? 0 : 24,
          right: sendByMe ? 24 : 0),
      alignment: sendByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
          margin: sendByMe
              ? EdgeInsets.only(left: 30)
              : EdgeInsets.only(right: 30),
          padding: EdgeInsets.only(
              top: 17, bottom: 17, left: 20, right: 20),
          decoration: BoxDecoration(
            borderRadius: sendByMe ? BorderRadius.only(
                topLeft: Radius.circular(23),
                topRight: Radius.circular(23),
                bottomLeft: Radius.circular(23)
            ) :
            BorderRadius.only(
                topLeft: Radius.circular(23),
                topRight: Radius.circular(23),
                bottomRight: Radius.circular(23)),
            gradient: LinearGradient(
                colors: sendByMe ? [
                const Color(0xff007EF4),
                const Color(0xff2A75BC)
                ]
                : [
                const Color(0x1AFFFFFF),
            const Color(0x1AFFFFFF)
            ],
          )
      ),
      child: Text(message,
          textAlign: TextAlign.start,
          style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'OverpassRegular',
              fontWeight: FontWeight.w300)),
    ),
    );
  }
}
