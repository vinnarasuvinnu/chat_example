import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vin_chat/helper.dart';

class DatabaseMethods {
  Future<void> addUserInfo(userData) async {

    FirebaseFirestore.instance.collection("users").add(userData).catchError((e) {
      print(e.toString());
    });
  }

  getUsers()async{
    return FirebaseFirestore.instance.collection("users").get();

  }


  getUserByName(String username)async{
    return FirebaseFirestore.instance.collection("users").where("name",isEqualTo: username).get();
  }

  getUserInfo(String email) async {
    return FirebaseFirestore.instance
        .collection("users")
        .where("userEmail", isEqualTo: email)
        .get()
        .catchError((e) {
      print(e.toString());
    });
  }

  searchByName(String searchField) {
    return FirebaseFirestore.instance
        .collection("users")
        .where('userName', isEqualTo: searchField)
        .get();
  }

  Future<bool> addChatRoom(chatRoom, chatRoomId) async{
    FirebaseFirestore.instance
        .collection("chatRoom")
        .doc(chatRoomId)
        .set(chatRoom)
        .catchError((e) {
      print(e);
    });
    return true;
  }

  getChats(String chatRoomId) async{

    return FirebaseFirestore.instance
        .collection("chatRoom")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy('time',descending: true).limit(Helper.pageLimit)
        .snapshots();
  }

  getChatsPagination(String chatRoomId,lastDoc) async{

    return FirebaseFirestore.instance
        .collection("chatRoom")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy('time',descending: true).startAfter([lastDoc]).limit(Helper.pageLimit)
        .snapshots();
  }



  Future<void> addMessage(String chatRoomId, chatMessageData)async{

    FirebaseFirestore.instance.collection("chatRoom")
        .doc(chatRoomId)
        .collection("chats")
        .add(chatMessageData).catchError((e){
      print(e.toString());
    });
    ;
  }

  getUserChats(String itIsMyName) async {
    return await FirebaseFirestore.instance
        .collection("chatRoom")
        .where('users', arrayContains: itIsMyName)
        .snapshots();
  }
  createChatRoom({required String chatRoomId,chatRoomMap}){
    FirebaseFirestore.instance.collection("ChatRoom").doc(chatRoomId).set(chatRoomMap).catchError((onError){
      print(onError.toString());
    });
  }

}