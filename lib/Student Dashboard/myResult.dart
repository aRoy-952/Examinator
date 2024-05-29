import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyResult extends StatefulWidget {
  const MyResult({Key? key}) : super(key: key);

  @override
  State<MyResult> createState() => _MyResultState();
}

class _MyResultState extends State<MyResult> {
  late Future<List<Map<String, dynamic>>> _fetchSubjectsAndMarks;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchSubjectsAndMarks = fetchSubjectsAndMarks();
  }

  Future<String?> fetchUserRegNo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection("users")
          .doc(user.uid)
          .get();
      return snapshot.data()!['regNo']; // Fetch regNo from user document
    } else {
      throw Exception('User not logged in');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSubjectsAndMarks() async {
    String? regNo = await fetchUserRegNo();
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Subjects').get();

    List<Map<String, dynamic>> subjectsAndMarks = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      String subjectName = doc['subjectName'];
      int numberOfQuestions =
          doc['numberOfQuestions']; // Fetch numberOfQuestions for the subject

      DocumentSnapshot marksSnapshot = await FirebaseFirestore.instance
          .collection('marks')
          .doc(subjectName)
          .get();

      if (marksSnapshot.exists &&
          (marksSnapshot.data() as Map<String, dynamic>).containsKey(regNo)) {
        int mark = (marksSnapshot.data() as Map<String, dynamic>)[
            regNo]; // Accessing mark for the specific regNo

        subjectsAndMarks.add({
          'subjectName': subjectName,
          'mark': mark,
          'totalMarks': numberOfQuestions * 10,
          // Calculate total marks based on numberOfQuestions
        });
      } else {
        subjectsAndMarks.add({
          'subjectName': subjectName,
          'mark': "NA",
          'totalMarks': numberOfQuestions * 10,
          // Set total marks as numberOfQuestions * 10
        });
      }
    }

    return subjectsAndMarks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Result Page',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.indigo[50],
      body: FutureBuilder(
        future: _fetchSubjectsAndMarks,
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            List<Map<String, dynamic>> subjectsAndMarks = snapshot.data!;
            return ListView.builder(
              itemCount: subjectsAndMarks.length,
              itemBuilder: (context, index) {
                final subjectAndMark = subjectsAndMarks[index];
                final subjectName = subjectAndMark['subjectName'];
                final mark = subjectAndMark['mark'];
                final totalMarks = subjectAndMark['totalMarks'];

                // Calculate percentage
                final double percentage =
                    mark == "NA" ? 0.0 : (mark / totalMarks) * 100;

                // Determine if passing criteria is met (at least 30%)
                final bool isPassing = mark != "NA" && percentage >= 30.0;

                // Determine card color based on passing criteria or NA
                final Color cardColor = mark == "NA"
                    ? Colors.grey[200]!
                    : (isPassing ? Colors.green[100]! : Colors.red[100]!);

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 10.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    color: cardColor,
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      title: Text(
                        subjectName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4.0),
                          Row(
                            children: [
                              Text(
                                'Marks: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                mark.toString(),
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                'Total Marks: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                totalMarks.toString(),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.0),
                          LinearProgressIndicator(
                            value: mark == "NA" ? 0.0 : percentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No subjects available.'));
          }
        },
      ),
    );
  }
}
