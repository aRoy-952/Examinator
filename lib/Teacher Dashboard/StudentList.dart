import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // Import Random class
import '../Navigation Control/home.dart'; // Import HomePage

class StudentList extends StatefulWidget {
  @override
  _StudentListState createState() => _StudentListState();
}

class _StudentListState extends State<StudentList> {
  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('users')
      .where('roleOfUser', isEqualTo: 'Student')
      .snapshots();

  Random _random = Random(); // Instantiate Random class

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(), // Navigate back to HomePage
          ),
        );
        return false; // Prevents the default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Colors.black,
          title: Text(
            'List of Students',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.indigo[50],
        body: StreamBuilder(
          stream: _usersStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text("Something went wrong");
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            List<DocumentSnapshot> sortedDocs = snapshot.data!.docs;
            sortedDocs.sort((a, b) => a['regNo'].compareTo(b['regNo']));

            return ListView.builder(
              itemCount: sortedDocs.length,
              itemBuilder: (_, index) {
                String name = sortedDocs[index]['name'];
                String regNo = sortedDocs[index]['regNo'];
                Color backgroundColor =
                    _generateColor(name); // Generate random color
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Card(
                    elevation: 3,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      leading: CircleAvatarWithInitials(
                        name: name,
                        backgroundColor: backgroundColor,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Reg No: $regNo',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      onTap: () {
                        // Add onTap logic here
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _generateColor(String name) {
    // Generate a random color using the Random class
    return Color.fromARGB(
      255,
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
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
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        HomePage(), // Navigate back to HomePage
                  ),
                );
              },
              child: Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}

class CircleAvatarWithInitials extends StatelessWidget {
  final String name;
  final Color backgroundColor;

  const CircleAvatarWithInitials({
    Key? key,
    required this.name,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> nameParts = name.split(' ');
    String initials = (nameParts.length > 1)
        ? '${nameParts[0][0]}${nameParts[1][0]}'
        : nameParts[0][0];

    return CircleAvatar(
      backgroundColor: backgroundColor,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
