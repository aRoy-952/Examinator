import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Screens/login.dart';
import '../fetchProfile/userProfile.dart';
import '../Student%20Dashboard/instructionToCanvas.dart';
import 'package:examinator/Student%20Dashboard/myResult.dart';

class studentdashboard extends StatefulWidget {
  const studentdashboard({Key? key}) : super(key: key);

  @override
  State<studentdashboard> createState() => _studentdashboardState();
}

class _studentdashboardState extends State<studentdashboard> with SingleTickerProviderStateMixin {
  int numberOfQuestions = 10; // Example value for numberOfQuestions
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    // Start the animation when the widget is built
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose(); // Dispose the animation controller
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await showLogoutDialog(context);
        return false; // Prevents the default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          title: Text(
            "Student Dashboard",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              onPressed: () {
                showLogoutDialog(context);
              },
              icon: Icon(Icons.logout),
              color: Colors.white,
            ),
          ],
        ),
        body: ListView(
          children: [
            buildContainer(
              "Profile",
              "assets/images/profile2.jpg",
              ProfilePage(),
              "Card",0, true
            ),
            SizedBox(height: 10),
            buildContainer(
              "Online Examination",
              "assets/images/onlineexam.png",
              InstructionToCanvass(
                  numberOfQuestions: numberOfQuestions),
              "Access",1, true
            ),
            SizedBox(height: 10),
            buildContainer(
              "Result",
              "assets/images/res4.jpg",
              MyResult(),
              "Access your marksheet",2, true
            ),
          ],
        ),
      ),
    );
  }

  Widget buildContainer(
      String title, String imageUrl, Widget page, String secondaryText, int index, bool startAnimation) {
    final Animation<double> animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval((index + 1) * 0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 50 - (50 * animation.value)),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300 + (index * 200)),
              transform: Matrix4.translationValues(startAnimation ? 0 : 900, 0, 0),
              margin: EdgeInsets.all(15),
              height: 355,
              width: 900,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
                child: Card(
                  elevation: 15.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image(
                          image: AssetImage(imageUrl),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black12.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 20,
                        child: SizedBox(
                          width: 400,
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              color: Color(0xFF2d3142),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 20,
                        child: Text(
                          secondaryText,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF2c0703),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

  Future<void> showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await logout(context); // Call logout function
              },
              child: Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}
