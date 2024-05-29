import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:examinator/Questions/questions.dart';
import 'package:examinator/global.dart';
import 'package:flutter/services.dart';

class SubjectListPage extends StatefulWidget {
  @override
  _SubjectListPageState createState() => _SubjectListPageState();
}

class _SubjectListPageState extends State<SubjectListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Subject List', style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.indigo[50],
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Subjects')
            .where('isLive',
                isEqualTo: true) // Filter documents where isLive is true
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

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      onTap: () {
                        if (timerExpiredMap.containsKey(subjectName) &&
                            timerExpiredMap[subjectName]!) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Sorry :('),
                              content: Text('You can\'t go back in!'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuestionListScreen(
                                subjectName: subjectName,
                              ),
                            ),
                          );
                        }
                      },
                      title: Text(
                        subjectName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18.0),
                      ),
                      leading: Icon(Icons.book, color: Colors.indigo),
                      trailing:
                          Icon(Icons.arrow_forward_ios, color: Colors.blueGrey),
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
    );
  }
}
