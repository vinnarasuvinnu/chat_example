import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vin_chat/appMessage.dart';
import 'package:vin_chat/chat_page.dart';
import 'package:vin_chat/helper.dart';
import 'package:vin_chat/messages.dart';
import 'package:vin_chat/register.dart';
import 'package:vin_chat/services/database.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DatabaseMethods databaseMethods = DatabaseMethods();
  late QuerySnapshot searchSnapshot;
  bool getSnapShot=false;
  TextEditingController searchTextEdititingController = TextEditingController();

  getChatRoomId(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }



  initiateSearch() {
    databaseMethods
        .getUsers()
        .then((val) {
      setState(() {
        searchSnapshot = val;
        getSnapShot = true;
      });
      print(searchSnapshot);
    });
  }
  createChatRoomAndStartConversation(String sender,String receiver){
    print("this gets called ***********************");
    String chatRoomId = getChatRoomId(sender, receiver);
    List<String> users=[sender,receiver];
    Map<String, dynamic> chatRoomMap={
      "users":users,
      "chatroomId":chatRoomId
    };
    databaseMethods.createChatRoom(chatRoomId:chatRoomId ,chatRoomMap:chatRoomMap);
    return chatRoomId;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initiateSearch();
  }

  Widget searchList() {
    return getSnapShot
        ? ListView.builder(
            itemCount: searchSnapshot.docs.length,
            shrinkWrap: true,
        itemBuilder: (context,index){
              return ListTile(
                onTap: ()async{
                  String chatroomId=await createChatRoomAndStartConversation(Helper.sender, searchSnapshot.docs[index].get('name'));
                  print(chatroomId);
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => ChateScreen(chatRoomId: chatroomId,)),
                  // );

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MessageList(chatRoomId: chatroomId,)),
                  );

                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => MessagePages(chatRoomId: chatroomId,)),
                  // );
                },
                title:Text(searchSnapshot.docs[index].get('name')),
                subtitle: Text(searchSnapshot.docs[index].get('email')),

              );
        }
    )
        : Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Vin Chat",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: searchList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegisterScreen()),
          );
          // Add your onPressed code here!
        },
        child: const Icon(Icons.app_registration),
        backgroundColor: Colors.green,
      ),
    );
  }
}
