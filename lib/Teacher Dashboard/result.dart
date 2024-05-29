import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_to_pdf/flutter_to_pdf.dart';
import 'package:path_provider/path_provider.dart';

class Result extends StatefulWidget {
  const Result({Key? key}) : super(key: key);

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  late Future<List<Map<String, dynamic>>> _fetchStudents;
  late Future<List<String>> _fetchSubjects;
  final ExportDelegate exportDelegate = ExportDelegate();

  @override
  void initState() {
    super.initState();
    _fetchStudents = fetchStudents();
    _fetchSubjects = fetchSubjects();
  }

  Future<List<Map<String, dynamic>>> fetchStudents() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('roleOfUser', isEqualTo: 'Student')
        .get();

    List<Map<String, dynamic>> students = [];
    querySnapshot.docs.forEach((doc) {
      students.add({
        'name': doc['name'],
        'roll': doc['regNo'], // Assuming 'regNo' is the field for roll number
      });
    });

    // Sort students based on roll numbers in ascending order
    students.sort((a, b) => a['roll'].compareTo(b['roll']));

    return students;
  }

  Future<List<String>> fetchSubjects() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Subjects').get();

    List<String> subjects = [];
    querySnapshot.docs.forEach((doc) {
      subjects.add(doc['subjectName']);
    });

    return subjects;
  }

  Future<Map<String, dynamic>> fetchMarks(String subject) async {
    DocumentSnapshot<Map<String, dynamic>> docSnapshot =
        await FirebaseFirestore.instance.collection('marks').doc(subject).get();

    if (docSnapshot.exists) {
      return docSnapshot.data()!;
    } else {
      return {'marks': 'NA'};
    }
  }

  Future<void> savePDF() async {
    final pdf = await exportDelegate.exportToPdfDocument('marksheetFrame');
    final file = File('/data/user/0/com.example.examinator/marksheet.pdf');
    await file.writeAsBytes(await pdf.save());
    print(file.path);
    // Provide feedback to the user that the PDF has been saved
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF saved successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExportFrame(
      frameId: 'marksheetFrame',
      exportDelegate: exportDelegate,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Class Marksheet',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        backgroundColor: Colors.indigo[50],
        body: FutureBuilder(
          future: Future.wait([_fetchStudents, _fetchSubjects]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              List<Map<String, dynamic>> students =
                  snapshot.data![0] as List<Map<String, dynamic>>;
              List<String> subjects = snapshot.data![1] as List<String>;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    dataRowHeight: 80, // Adjust the row height
                    columns: [
                      DataColumn(
                        label: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Students'),
                        ),
                      ),
                      for (String subject in subjects)
                        DataColumn(
                          label: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(subject),
                          ),
                        ),
                    ],
                    rows: List<DataRow>.generate(
                      students.length,
                      (index) => DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            return index.isEven
                                ? Colors.grey.withOpacity(0.3)
                                : null;
                          },
                        ),
                        cells: [
                          DataCell(
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: ListTile(
                                title: Text(
                                  students[index]['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  'Roll: ${students[index]['roll']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.deepPurple[900],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          for (String subject in subjects)
                            DataCell(
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                alignment: Alignment.center,
                                child: FutureBuilder(
                                  future: fetchMarks(subject),
                                  builder: (context,
                                      AsyncSnapshot<Map<String, dynamic>>
                                          marksSnapshot) {
                                    if (marksSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    } else if (marksSnapshot.hasError) {
                                      return Text('Error');
                                    } else if (marksSnapshot.hasData) {
                                      Map<String, dynamic> marksData =
                                          marksSnapshot.data!;
                                      String mark = marksData.containsKey(
                                              students[index]['roll'])
                                          ? marksData[students[index]['roll']]
                                              .toString()
                                          : 'NA';
                                      return Text(
                                        mark,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      );
                                    } else {
                                      return Text(
                                        'NA',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return Center(child: Text('No data available.'));
            }
          },
        ),
      ),
    );
  }
}
