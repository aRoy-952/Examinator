import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Screens/login.dart';
import 'package:examinator/fetchProfile/userProfile.dart';
import 'result.dart';
import '../Teacher Dashboard/examination_control_settings.dart'; // Import the screen for Examination Control and Settings

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
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
        await showLogoutDialog(context); // Show logout confirmation dialog
        return false; // Prevents the default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black, // Make app bar transparent
          title: Text(
            "Teacher Dashboard",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await showLogoutDialog(
                    context); // Show logout confirmation dialog
              },
              icon: Icon(Icons.logout),
              color: Colors.white,
            ),
          ],
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Container(
          height: 1520,
          width: 900,
          // color: Colors.indigo[50],
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: 3,
                    itemBuilder: (context, int index) {
                      if (index == 0) {
                        return buildFeatureItem(
                            "Profile",
                            "assets/images/profile2.jpg",
                            ProfilePage(),
                            context,
                            0);
                      } else if (index == 1) {
                        return buildFeatureItem(
                            "Examination Settings",
                            "assets/images/exam8.png",
                            ExaminationControlSettings(),
                            context,
                            1);
                      } else if (index == 2) {
                        return buildFeatureItem("Result",
                            "assets/images/res3.jpg", Result(), context, 2);
                      }
                      return const SizedBox.shrink();
                    }),
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFeatureItem(String title, String imagePath, Widget page,
      BuildContext context, int index) {
    final Animation<double> animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval((index + 1) * 0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: Opacity(
            opacity: animation.value,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => page)),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: Container(
                  width: 300,
                  height: 400,
                  margin: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      if (_isHovered)
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Image.asset(
                          imagePath,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black12.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
