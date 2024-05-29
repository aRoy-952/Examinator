import 'package:ff_navigation_bar_plus/ff_navigation_bar_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Screens/login.dart';
import '../User Model/model.dart';
import 'StudentList.dart';
import 'subjectSettings.dart';
import 'teacherDashboard.dart';

class Teacher extends StatefulWidget {
  final String id;
  Teacher({required this.id});

  @override
  _TeacherState createState() => _TeacherState(id: id);
}

class _TeacherState extends State<Teacher> {
  String id;
  var role_of_userl;
  var emaill;
  UserModel loggedInUser = UserModel();
  PageController _pageController = PageController();

  List<Widget> pages = <Widget>[
    HomePage(),
    StudentList(),
    SubjectSettingsPage()
  ];

  int selectedIndex = 0;

  _TeacherState({required this.id});

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance.collection("users").doc(id).get().then((value) {
      this.loggedInUser = UserModel.fromMap(value.data()!);
    }).whenComplete(() {
      setState(() {
        emaill = loggedInUser.email.toString();
        role_of_userl = loggedInUser.roleOfUser.toString();
        id = loggedInUser.uid.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: pages,
        onPageChanged: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: FFNavigationBar(
        theme: FFNavigationBarTheme(
          barBackgroundColor: Color(0xFF33415C), // Dark blueish-gray
          selectedItemBorderColor: Color(0xFF1E2B3C), // Dark blueish-gray (slightly darker)
          selectedItemBackgroundColor: Color(0xFF1E2B3C), // Dark blueish-gray
          selectedItemIconColor: Colors.white, // White
          selectedItemLabelColor: Colors.white, // White
          unselectedItemIconColor: Colors.white70, // Lighter white
          unselectedItemLabelColor: Colors.white, // White
        ),
        selectedIndex: selectedIndex,
        onSelectTab: (index) {
          setState(() {
            selectedIndex = index;
            _pageController.animateToPage(
              index,
              duration: Duration(milliseconds: 500), // Change the duration here
              curve: Curves.easeInOut, // Use a different curve if needed
            );
          });
        },
        items: [
          FFNavigationBarItem(
            iconData: Icons.home,
            label: 'Main Dashboard',
          ),
          FFNavigationBarItem(
            iconData: Icons.people,
            label: 'Students',
          ),
          FFNavigationBarItem(
            iconData: Icons.settings,
            label: 'Exam Control',
          ),
        ],
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    CircularProgressIndicator();
    await FirebaseAuth.instance.signOut();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }
}
