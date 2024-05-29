import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Student Dashboard/studentdashboard.dart';
import '../User Model/model.dart';
import '../Teacher Dashboard/teacher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  _HomePageState();

  @override
  Widget build(BuildContext context) {
    return contro();
  }
}

class contro extends StatefulWidget {
  contro();

  @override
  _controState createState() => _controState();
}

class _controState extends State<contro> {
  _controState();

  User? user = FirebaseAuth.instance.currentUser;
  UserModel loggedInUser = UserModel();
  var role_of_userl;
  var emaill;
  var id;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot value = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get();

      this.loggedInUser = UserModel.fromMap(value.data()!);

      setState(() {
        emaill = loggedInUser.email.toString();
        role_of_userl = loggedInUser.roleOfUser.toString();
        id = loggedInUser.uid.toString();
      });

      navigateBasedOnRole();
    } catch (e) {
      print("Error fetching user data: $e");
      // Handle the error as needed
    }
  }

  void navigateBasedOnRole() {
    if (role_of_userl == 'Student') {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => studentdashboard()));
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Teacher(id: id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
