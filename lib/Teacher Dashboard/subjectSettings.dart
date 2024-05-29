import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Navigation Control/home.dart';
import 'examinationControlEdit.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubjectSettingsPage extends StatefulWidget {
  @override
  _SubjectSettingsPageState createState() => _SubjectSettingsPageState();
}

class _SubjectSettingsPageState extends State<SubjectSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Wrap with WillPopScope
      onWillPop: () async {
        // Handle back button press
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(), // Navigate to StudentList
          ),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
          title: Text(
            'Examination Control',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('Subjects')
              .where('uploadedBy', isEqualTo: _auth.currentUser?.email)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var subjectData = snapshot.data!.docs[index];
                  var subjectName = subjectData['subjectName'];
                  var isLive = subjectData['isLive']; // Retrieve isLive field
                  var documentId = subjectData.id; // Access document ID directly

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Card(
                      elevation: 4, // Add elevation for a shadow effect
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(8.0), // Add rounded corners
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ExaminationControlEditSettings(
                                    subjectName: subjectName,
                                    documentId: documentId,
                                  ),
                            ),
                          );
                        },
                        title: Text(
                          subjectName,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        trailing: AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: Switch(
                            value: isLive,
                            onChanged: (newValue) {
                              _toggleSubjectLiveStatus(documentId, newValue);
                            },
                            activeColor: Colors.green, // Set active color to green
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
            return Center(
              child: Text('No subjects available.'),
            );
          },
        ),
      ),
    );
  }

  void _toggleSubjectLiveStatus(String documentId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('Subjects')
          .doc(documentId)
          .update({'isLive': newStatus});

      // Show a success message using SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(newStatus ? 'Subject is now live' : 'Subject is not live'),
          duration: Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      print('Error toggling subject live status: $e');
      // Handle errors as needed
    }
  }
}



