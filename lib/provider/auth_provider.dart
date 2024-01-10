import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:phoneauth_firebase/screens/otp_screen.dart';
import 'package:phoneauth_firebase/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/user_model.dart';

class AuthProvider extends ChangeNotifier{

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _uid;
  String get uid => _uid!;

  UserModel? _userModel;
  UserModel get userModel => _userModel!;



  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFireStore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;



  AuthProvider(){
    checkSignIn();
  }


  void checkSignIn() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    _isSignedIn = s.getBool("is_signedin") ?? false;
    notifyListeners();
  }

  Future setSignIn() async {
     final SharedPreferences s = await SharedPreferences.getInstance();
     s.setBool("is_signedin", true);
     _isSignedIn = true;
     notifyListeners();
  }

  void signInWithPhone(BuildContext context, String phoneNumber) async {
    try{

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential phoneAuthCredential) async {
          await _firebaseAuth.signInWithCredential(phoneAuthCredential);
        }, 
        verificationFailed: (error){
          throw Exception(error.message);
        }, 
        codeSent: (verificationId, forceResendingToken) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => OtpScreen(
              verificationId: verificationId
            )));
        }, 
        codeAutoRetrievalTimeout: (verificationId){

        });


    } on FirebaseAuthException catch(e){

      showSnackBar(context, e.message.toString());

    }
  }


  // verify otp
  void verifyOtp({
    required BuildContext context,
    required String verificationId,
    required String userOtp,
    required Function onSuccess,
  }) async {
      _isLoading = true;
      notifyListeners();

      try{
            PhoneAuthCredential creds = PhoneAuthProvider.credential(
              verificationId: verificationId, 
              smsCode: userOtp);
              User? user = (await _firebaseAuth.signInWithCredential(creds)).user!;

              if(user != null){
                //carry our logic
                _uid = user.uid;
                onSuccess();
              }

              _isLoading = false;
              notifyListeners();
      } on FirebaseAuthException catch (e){
        showSnackBar(context, e.message.toString());
         _isLoading = false;
         notifyListeners();
      }

  }


  //DATABASE OPERATIONS
  Future<bool> checkExistingUser() async {
      DocumentSnapshot snapshot = await _firebaseFireStore.collection("users").doc(_uid).get();
      if(snapshot.exists){
        print("USER EXISTS");
        return true;
      }else {
         print("NEW USER");
      return false;
      }
  }



void saveUserDataToFirebase({
    required BuildContext context,
    required UserModel userModel,
    required File profilePic,
    required Function onSuccess,
  }) async {
    _isLoading = true;
    notifyListeners();
    try{
      print("one");
      // uploading image to firebase storage
      await storeFileToStorage("profilePic/$_uid", profilePic).then((value) {
        userModel.profilePic = value;
        userModel.createdAt = DateTime.now().millisecondsSinceEpoch.toString();
        userModel.phoneNumber = _firebaseAuth.currentUser!.phoneNumber!;
        userModel.uid = _firebaseAuth.currentUser!.uid;
        print("two");
      });

      _userModel = userModel;

      // uploading to database
      await _firebaseFireStore.collection("users").doc(_uid).set(userModel.toMap()).then((value) {
         print("three");
        onSuccess();
        _isLoading = false;
        notifyListeners();
      });

    } on FirebaseAuthException catch(e){
       print("four");
      showSnackBar(context, e.message.toString());
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<String> storeFileToStorage(String ref, File file) async {
    UploadTask uploadTask = _firebaseStorage.ref().child(ref).putFile(file);
    TaskSnapshot snapshot  = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future getDataFromFireStore() async {
    await _firebaseFireStore.collection("users").doc(_firebaseAuth.currentUser!.uid).get().then((DocumentSnapshot snapshot) {
      _userModel = UserModel(
        name: snapshot['name'], 
        email: snapshot['email'], 
        bio: snapshot['bio'], 
        profilePic: snapshot['profilePic'], 
        createdAt: snapshot['createdAt'], 
        phoneNumber: snapshot['phoneNumbr'], 
        uid: snapshot['uid']
        );
        _uid = userModel.uid;
    });
  }


  // Storing DATA Locally using SharedPreference
  Future saveUserDataToSP() async {
    SharedPreferences s = await SharedPreferences.getInstance();
    await s.setString("user_model", jsonEncode(userModel.toMap()));
  }


Future getDataFromSP() async {
  SharedPreferences s = await SharedPreferences.getInstance();
  String data = s.getString("user_model") ?? '';
  _userModel = UserModel.fromMap(jsonDecode(data));
  _uid = _userModel!.uid;
  notifyListeners();
}

Future userSignOut() async {
  SharedPreferences s = await SharedPreferences.getInstance();
  await _firebaseAuth.signOut();
  _isSignedIn = false;
  notifyListeners();
  s.clear();
}


}



