import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late UserModel _userModel = UserModel(); // Initialize with an empty UserModel
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadProfileDetails();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await _firestore.collection("users").doc(user.uid).get();
      setState(() {
        _userModel = UserModel.fromMap(snapshot.data()!);
      });
    }
  }

  String _generateInitials(String name) {
    List<String> names = name.split(" ");
    String initials = "";

    for (String name in names) {
      initials += name.isNotEmpty ? name[0].toUpperCase() : '';
    }

    return initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Card',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.indigo[50],
      body: Center(
        child: _userModel.name != null &&
            _userModel.email != null &&
            _userModel.roleOfUser != null &&
            _userModel.regNo != null
            ? SizedBox(
          width: 600,
          child: GestureDetector(
            onTap: () {
              if (_animationController.status ==
                  AnimationStatus.completed) {
                _animationController.reverse();
              } else {
                _animationController.forward();
              }
            },
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(
                        _animation.value * 3.14), // Adjust rotation
                  alignment: Alignment.center,
                  child: _animation.value < 0.5
                      ? _buildProfileCard(_userModel)
                      : _buildProfileCardBack(),
                );
              },
            ),
          ),
        )
            : const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildProfileCard(UserModel userModel) {
    return Card(
      elevation: 180,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5C6BC0), Color(0xFF303f9f)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return constraints.maxWidth < 600
                  ? _buildProfileContentSmallScreen(userModel)
                  : _buildProfileContentLargeScreen(userModel);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContentSmallScreen(UserModel userModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20), // Add space at the top
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 50,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 50,
            child: Text(
              _generateInitials(userModel.name!),
              style: TextStyle(
                fontSize: 50,
                color: Colors.indigo[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        _buildProfileDetail(
            'Name', userModel.name!, Icons.person, Colors.white),
        SizedBox(height: 10),
        _buildProfileDetail(
            'Email', userModel.email!, Icons.email, Colors.white),
        SizedBox(height: 10),
        _buildProfileDetail(
            'Reg No', userModel.regNo!, Icons.confirmation_number, Colors.white),
        SizedBox(height: 10),
        _buildProfileDetail(
            'Role', userModel.roleOfUser!, Icons.work, Colors.white),
      ],
    );
  }

  Widget _buildProfileContentLargeScreen(UserModel userModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20), // Add space at the top
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 50,
            child: Text(
              _generateInitials(userModel.name!),
              style: TextStyle(
                fontSize: 50,
                color: Colors.pinkAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileDetail(
                'Name', userModel.name!, Icons.person, Colors.white),
            SizedBox(height: 10),
            _buildProfileDetail(
                'Email', userModel.email!, Icons.email, Colors.white),
            SizedBox(height: 10),
            _buildProfileDetail(
                'Reg No', userModel.regNo!, Icons.confirmation_number, Colors.white),
            SizedBox(height: 10),
            _buildProfileDetail(
                'Role', userModel.roleOfUser!, Icons.work, Colors.white),
            // Add more details if needed
          ],
        ),
      ],
    );
  }

  Widget _buildProfileDetail(
      String label, String value, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 35,
          color: iconColor,
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCardBack() {
    return SizedBox(
      height: 450, // Adjust the height as needed
      child: Card(
        elevation: 180,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [Color(0xFF5C6BC0), Color(0xFF303f9f)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.1415), // Rotate 180 degrees horizontally
            child: Text(
              _userModel.regNo!,
              style: TextStyle(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class UserModel {
  String? uid;
  String? email;
  String? name;
  String? roleOfUser;
  String? regNo;

  UserModel();

  UserModel.fromMap(Map<String, dynamic> map) {
    uid = map['uid'];
    email = map['email'];
    name = map['name'];
    roleOfUser = map['roleOfUser'];
    regNo = map['regNo']; // Fetch regNo from map
  }
}
