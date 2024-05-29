import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ExaminationControlEditSettings extends StatefulWidget {
  final String subjectName;
  final String documentId;

  ExaminationControlEditSettings(
      {required this.subjectName, required this.documentId});

  @override
  _ExaminationControlEditSettingsState createState() =>
      _ExaminationControlEditSettingsState();
}

class _ExaminationControlEditSettingsState
    extends State<ExaminationControlEditSettings> {
  int _numberOfQuestions = 0;
  TextEditingController _subjectController = TextEditingController();
  int _selectedHours = 0;
  int _selectedMinutes = 0;
  File? _selectedPdf;
  String? _selectedPdfName;
  List<TextEditingController> _questionControllers = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLive = false; // Track live status

  @override
  void initState() {
    super.initState();
    _fetchPreviousSettings();
  }

  void _fetchPreviousSettings() async {
    try {
      final DocumentSnapshot subjectSnapshot = await FirebaseFirestore.instance
          .collection('Subjects')
          .doc(widget.documentId)
          .get();

      setState(() {
        _subjectController.text = subjectSnapshot['subjectName'];
        _numberOfQuestions = subjectSnapshot['numberOfQuestions'];

        // Convert exam duration from minutes to hours and minutes
        int totalMinutes = subjectSnapshot['examDuration'];
        _selectedHours = totalMinutes ~/ 60;
        _selectedMinutes = totalMinutes % 60;
        _selectedPdfName = subjectSnapshot['pdfName'];
        _isLive = subjectSnapshot['isLive'] ?? false; // Update _isLive
      });

      // Fetch answers from Reference Answers collection
      final referenceAnswersSnapshot = await FirebaseFirestore.instance
          .collection('Reference Answers')
          .doc(widget
              .subjectName) // Assuming subjectName is the name of the subject
          .get();

      // Populate _questionControllers with fetched answers
      List<String?> answers = [];
      for (int i = 1; i <= _numberOfQuestions; i++) {
        String answerKey = 'Answer_$i';
        answers.add(referenceAnswersSnapshot[answerKey]);
      }

      setState(() {
        _questionControllers = answers
            .map((answer) => TextEditingController(text: answer))
            .toList();
      });
    } catch (e) {
      print('Error fetching previous settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('General Settings'),
            _buildGeneralSettings(),
            SizedBox(height: 20.0),
            _buildSectionTitle('Question Settings'),
            _buildQuestionSettings(),
            SizedBox(height: 20.0),
            _buildSectionTitle('Exam Duration'),
            _buildExamDuration(),
            SizedBox(height: 20.0),
            _buildSectionTitle('PDF Upload'),
            _buildPdfUpload(),
            SizedBox(height: 20.0),
            _buildActionButtons(),
          ],
        ),
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

  Widget _buildGeneralSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Subject Name:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Enter subject name',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
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
            _buildQuestionTextFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildExamDuration() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                value: _selectedHours,
                onChanged: (newValue) {
                  setState(() {
                    _selectedHours = newValue!;
                  });
                },
                items: List.generate(
                  6,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text('$index hours'),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: DropdownButton<int>(
                value: _selectedMinutes,
                onChanged: (newValue) {
                  setState(() {
                    _selectedMinutes = newValue!;
                  });
                },
                items: List.generate(
                  60,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text('$index minutes'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfUpload() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedPdfName ?? 'No PDF selected',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: _selectPdf,
              child: Text('Select PDF'),
            ),
          ],
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
              hintText: 'Enter answer for Question ${i + 1}',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      );
    }
    return Column(
      children: textFields,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _updateSettingsInFirestore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
              ),
              child: Text(
                'Update',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: _toggleLive,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLive
                    ? Colors.green
                    : Colors.indigo, // Change button color based on _isLive
              ),
              child: Text(
                _isLive ? 'Live' : 'Go Live',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _deleteSubject,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text(
            'Delete Subject',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _deleteSubject() async {
    try {
      // Delete document from Subjects collection
      await FirebaseFirestore.instance
          .collection('Subjects')
          .doc(widget.documentId)
          .delete();

      // Delete document from Reference Answers collection
      await FirebaseFirestore.instance
          .collection('Reference Answers')
          .doc(widget.subjectName)
          .delete();

      // Show a success message using SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subject deleted successfully'),
        ),
      );

      // Navigate back to the previous screen
      Navigator.pop(context);
    } catch (e) {
      print('Error deleting subject: $e');
      // Handle errors as needed
    }
  }

  void _updateSettingsInFirestore() async {
    try {
      final DocumentSnapshot subjectSnapshot = await FirebaseFirestore.instance
          .collection('Subjects')
          .doc(widget.documentId)
          .get();

      // Get previous values from Firestore
      String previousSubjectName = subjectSnapshot['subjectName'];
      int previousNumberOfQuestions = subjectSnapshot['numberOfQuestions'];
      int previousExamDuration = subjectSnapshot['examDuration'];
      String previousPdfName = subjectSnapshot['pdfName'];

      // Prepare a map to store updated fields
      Map<String, dynamic> updatedSubjectFields = {};

      // Check if values are different and add them to the map if changed
      if (_subjectController.text != previousSubjectName) {
        updatedSubjectFields['subjectName'] = _subjectController.text;
      }
      if (_numberOfQuestions != previousNumberOfQuestions) {
        updatedSubjectFields['numberOfQuestions'] = _numberOfQuestions;
      }
      int newExamDuration = _selectedHours * 60 + _selectedMinutes;
      if (newExamDuration != previousExamDuration) {
        updatedSubjectFields['examDuration'] = newExamDuration;
      }
      if (_selectedPdfName != previousPdfName) {
        updatedSubjectFields['pdfName'] = _selectedPdfName;
      }

      // Update other fields in Subjects collection
      if (updatedSubjectFields.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('Subjects')
            .doc(widget.documentId)
            .update(updatedSubjectFields);
      }

      // Update answers in Reference Answers collection
      Map<String, dynamic> updatedAnswers = {};
      for (int i = 0; i < _questionControllers.length; i++) {
        String answerKey = 'Answer_${i + 1}';
        String newAnswer = _questionControllers[i].text;
        updatedAnswers[answerKey] = newAnswer;
      }

      await FirebaseFirestore.instance
          .collection('Reference Answers')
          .doc(widget.subjectName)
          .update(updatedAnswers);

      // Show a success message using SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings updated successfully'),
        ),
      );

      // Navigate back to the previous screen
      Navigator.pop(context);
    } catch (e) {
      print('Error updating settings: $e');
      // Handle errors as needed
    }
  }

  void _selectPdf() async {
    final pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (pickedFile != null) {
      setState(() {
        _selectedPdf = File(pickedFile.files.single.path!);
        _selectedPdfName = pickedFile.files.single.name!;
      });

      // Upload the selected PDF file to Firebase Storage
      try {
        final pdfFileName = 'Question Papers/${_selectedPdf!.path.split('/').last}';
        final Reference storageRef = FirebaseStorage.instance.ref().child(pdfFileName);
        await storageRef.putFile(_selectedPdf!);

        // Get the download URL of the uploaded file
        final String downloadURL = await storageRef.getDownloadURL();

        // Update the PDF name and URL in Firestore
        await FirebaseFirestore.instance
            .collection('Subjects')
            .doc(widget.documentId)
            .update({
          'pdfName': _selectedPdfName,
          'pdfUrl': downloadURL,
        });

        // Show a success message using SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF uploaded successfully'),
          ),
        );
      } catch (error) {
        print('Error uploading PDF: $error');
        // Handle errors as needed
      }
    }
  }


  void _toggleLive() async {
    try {
      await FirebaseFirestore.instance
          .collection('Subjects')
          .doc(widget.documentId)
          .update({'isLive': !_isLive}); // Toggle live status

      // Update _isLive variable
      setState(() {
        _isLive = !_isLive;
      });

      // Show a success message using SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isLive ? 'Subject is now live' : 'Subject is no longer live'),
          duration: Duration(milliseconds: 30),
        ),
      );
    } catch (e) {
      print('Error toggling live status: $e');
      // Handle errors as needed
    }
  }
}
