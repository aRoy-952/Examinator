import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Import Spinkit
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../Screens/numberpicker.dart';

class ExaminationControlSettings extends StatefulWidget {
  @override
  _ExaminationControlSettingsState createState() =>
      _ExaminationControlSettingsState();
}

class _ExaminationControlSettingsState
    extends State<ExaminationControlSettings> {
  int _numberOfQuestions = 1;
  TextEditingController _subjectController = TextEditingController();
  int _selectedHours = 0;
  int _selectedMinutes = 0;
  File? _selectedPdf;
  String? _selectedPdfName;
  List<TextEditingController> _questionControllers = [];
  bool _isLoading = false; // Add a boolean to control the loading state

  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _questionControllers.add(TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Examination Control and Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.indigo[50],
      body: Stack( // Wrap your body with a Stack
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildSectionTitle('Subject Name'),
                  _buildSubjectInformation(),
                  SizedBox(height: 20.0),
                  _buildSectionTitle('Number of Questions'),
                  _buildNumberOfQuestions(),
                  SizedBox(height: 20.0),
                  _buildSectionTitle('Question Details'),
                  _buildQuestionDetails(),
                  SizedBox(height: 20.0),
                  _buildSectionTitle('Exam Duration'),
                  _buildExamDuration(),
                  SizedBox(height: 20.0),
                  _buildSectionTitle('Upload Question Paper PDF'),
                  _buildPdfUpload(),
                  SizedBox(height: 20.0),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
          if (_isLoading) // Show loader if _isLoading is true
            Container(
              color: Colors.black.withOpacity(0.5), // Semi-transparent black background
              child: Center(
                child: SpinKitThreeBounce( // Spinkit loader
                  color: Colors.white,
                  size: 50.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSubjectInformation() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10.0),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject Name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors
                    .transparent, // Match the background color of other fields
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberOfQuestions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  if (_numberOfQuestions > 1) {
                    _numberOfQuestions--;
                    _questionControllers.removeLast();
                  }
                });
              },
            ),
            Text(
              '$_numberOfQuestions',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.0),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                setState(() {
                  _numberOfQuestions++;
                  _questionControllers.add(TextEditingController());
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionDetails() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: _buildQuestionTextFields(),
      ),
    );
  }

  Widget _buildExamDuration() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CustomTimePicker(
          initialHours: _selectedHours,
          initialMinutes: _selectedMinutes,
          onChanged: (hours, minutes) {
            setState(() {
              _selectedHours = hours;
              _selectedMinutes = minutes;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPdfUpload() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                pickFile();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.indigo, // Change the background color to indigo
              ),
              child: Text(
                'Select Question Paper PDF',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 10.0),
            _selectedPdfName != null
                ? Text(
              'Selected PDF: $_selectedPdfName',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            )
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          if (_validateFields()) {
            _saveData(
              _subjectController.text,
              _numberOfQuestions,
              _selectedPdf!,
              _selectedHours * 60 + _selectedMinutes,
              context,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green, // Change the background color to green
        ),
        child: Text(
          'Upload',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildQuestionTextFields() {
    List<Widget> textFields = [];
    for (var i = 0; i < _questionControllers.length; i++) {
      textFields.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _questionControllers[i],
            decoration: InputDecoration(
              labelText: 'Answer ${i + 1}',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: textFields,
    );
  }

  bool _validateFields() {
    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a subject name.'),
        ),
      );
      return false;
    }

    if (_numberOfQuestions <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a valid number of questions.'),
        ),
      );
      return false;
    }

    if (_selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a PDF file.'),
        ),
      );
      return false;
    }

    if (_selectedHours == 0 && _selectedMinutes < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exam duration must be at least 5 minutes.'),
        ),
      );
      return false;
    }

    if (_questionControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide at least one question.'),
        ),
      );
      return false;
    }

    // Check if any question is empty
    for (var controller in _questionControllers) {
      if (controller.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please provide all question details.'),
          ),
        );
        return false;
      }
    }

    return true;
  }

  void pickFile() async {
    final pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (pickedFile != null) {
      setState(() {
        _selectedPdf = File(pickedFile.files.single.path!);
        _selectedPdfName = pickedFile.files.single.name!;
      });
    }
  }

  Future<void> _saveData(
      String subjectName,
      int numberOfQuestions,
      File pdfFile,
      int examDuration,
      BuildContext context,
      ) async {
    try {
      setState(() {
        _isLoading = true; // Show loader
      });

      if (!mounted) return;

      if (_currentUser != null) {
        final CollectionReference subjectsCollection =
        FirebaseFirestore.instance.collection('Subjects');
        final CollectionReference referenceAnswersCollection =
        FirebaseFirestore.instance.collection('Reference Answers');

        String userName =
            _currentUser!.displayName ?? _currentUser!.email ?? '';

        // Upload PDF
        final pdfReference = FirebaseStorage.instance
            .ref()
            .child("Question Papers/${_selectedPdf!.path.split('/').last}");
        final pdfUploadTask = pdfReference.putFile(_selectedPdf!);
        await pdfUploadTask.whenComplete(() {});
        final pdfDownloadLink = await pdfReference.getDownloadURL();

        // Save subject data
        await subjectsCollection.doc(subjectName).set({
          'subjectName': subjectName,
          'numberOfQuestions': numberOfQuestions,
          'uploadedBy': userName,
          'timestamp': DateTime.now(),
          'pdfName': _selectedPdf!.path.split('/').last,
          'pdfUrl': pdfDownloadLink,
          'examDuration': examDuration,
          'isLive': false, // Add the isLive field with initial value false
        });

        // Save reference answers
        Map<String, dynamic> referenceAnswersData = {};
        for (var i = 0; i < _questionControllers.length; i++) {
          referenceAnswersData['Answer_${i + 1}'] =
              _questionControllers[i].text;
        }

        await referenceAnswersCollection
            .doc(subjectName)
            .set(referenceAnswersData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$subjectName with $numberOfQuestions Questions submitted successfully!',
            ),
          ),
        );

        setState(() {
          _numberOfQuestions = 0;
          _subjectController.clear();
          _selectedPdf = null;
          _selectedPdfName = null;
          _selectedHours = 0;
          _selectedMinutes = 0;
          _questionControllers.clear();
        });
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User not logged in!',
            ),
          ),
        );
      }

      setState(() {
        _isLoading = false; // Hide loader
      });
    } catch (e) {
      print('Error saving data: $e');
      setState(() {
        _isLoading = false; // Hide loader in case of error
      });
    }
  }
}
