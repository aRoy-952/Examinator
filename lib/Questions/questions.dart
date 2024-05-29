import 'dart:async';
import 'package:examinator/pdfView/pdf_view_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide Ink;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../api.dart';
import '../digital_ink_recognition/NewPage.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:examinator/global.dart';

class QuestionListScreen extends StatefulWidget {
  final String subjectName;

  QuestionListScreen({required this.subjectName});
  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen>
    with WidgetsBindingObserver {
  List<int> questionNumbers = [];
  Map<int, List<Ink>> _questionPagesMap = {};
  Map<int, List<List<StrokePoint>>> _questionPointsListsMap = {};
  int examDurationInSeconds = 0;
  String? pdfUrl;
  late Timer countdownTimer;
  bool _isMounted = false;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjectData(widget.subjectName);
    _fetchExamDuration(widget.subjectName);
    _isMounted = true;
    WidgetsBinding.instance!.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersive,
      overlays: [SystemUiOverlay.top],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    countdownTimer.cancel();
    _isMounted = false;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // Call your saveData function here
      submitData();
    }
  }

  void submitData() {
    timerExpiredMap[widget.subjectName] = true; // Mark subject timer as expired
    _submitButtonPressed(isManual: false);
  }

  Future<void> _fetchSubjectData(String subjectName) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Subjects')
          .where('subjectName', isEqualTo: subjectName)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        int numberOfQuestions = data['numberOfQuestions'] as int;
        setState(() {
          questionNumbers =
              List.generate(numberOfQuestions, (index) => index + 1);
          pdfUrl = data['pdfUrl'] as String?;
        });
      } else {
        print('Subject not found');
        setState(() {
          questionNumbers = [];
          pdfUrl = null;
        });
      }
    } catch (e) {
      print('Error fetching subject data: $e');
    }
  }

  Future<void> _fetchExamDuration(String subjectName) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Subjects')
          .where('subjectName', isEqualTo: subjectName)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        int durationInMinutes = querySnapshot.docs.first['examDuration'] as int;
        int durationInSeconds = durationInMinutes * 60;
        setState(() {
          examDurationInSeconds = durationInSeconds;
          startCountdownTimer();
        });
      } else {
        print('Subject not found');
      }
    } catch (e) {
      print('Error fetching exam duration: $e');
    }
  }

  void _showTimeExpiredDialog() {
    if (!_isDialogOpen) {
      // Open the dialog only if it's not already open
      _isDialogOpen = true; // Set flag to true
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dialog from closing on tap outside
        builder: (context) => AlertDialog(
          title: Text('Time Expired'),
          content: Text('Your answers have been automatically submitted.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                _isDialogOpen = false; // Set flag to false
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void startCountdownTimer() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isMounted) {
        setState(() {
          if (examDurationInSeconds > 0) {
            examDurationInSeconds--;
          } else {
            timer.cancel();
            timerExpiredMap[widget.subjectName] =
                true; // Mark subject timer as expired
            _submitButtonPressed(isManual: false);
            _showTimeExpiredDialog(); // Show the time expired dialog
          }
        });
      }
    });
  }

  Future<bool> _onWillPop() async {
    bool confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Exam?'),
        content: Text('Are you sure you want to leave the exam?'
            '\nYou will not be able to attempt the exam again!'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              // Set timerExpired to true for the current subject
              timerExpiredMap[widget.subjectName] = true;
              Navigator.of(context).pop(true);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {},
        child: WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black,
              leading: customDrawerIndicator(),
              title: Text(
                'Question List',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Save',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.save),
                  onPressed: _saveButtonPressed,
                  tooltip: 'Save',
                  color: Colors.white,
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Swipe right or tap on the above icon to view the question paper',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                buildTimeRemainingSection(examDurationInSeconds),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: questionNumbers.length,
                          itemBuilder: (context, index) {
                            final questionNumber = questionNumbers[index];
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (!_questionPagesMap
                                      .containsKey(questionNumber)) {
                                    _questionPagesMap[questionNumber] = [Ink()];
                                    _questionPointsListsMap[questionNumber] = [
                                      []
                                    ];
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DigitalInkView(
                                        questionNumber: questionNumber,
                                        initialPages: List.from(
                                            _questionPagesMap[questionNumber]!),
                                        initialPointsLists: List.from(
                                            _questionPointsListsMap[
                                                questionNumber]!),
                                      ),
                                    ),
                                  ).then((value) {
                                    if (value != null &&
                                        value is List<List<dynamic>>) {
                                      setState(() {
                                        _questionPagesMap[questionNumber] =
                                            value[0] as List<Ink>;
                                        _questionPointsListsMap[
                                                questionNumber] =
                                            value[1] as List<List<StrokePoint>>;
                                      });
                                    }
                                  });
                                },
                                child:
                                    Text('Answer for Question $questionNumber'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            drawer: SizedBox(
              width: double.infinity,
              child: Drawer(
                elevation: 0,
                child: Container(
                  color: Colors.white,
                  child: pdfUrl != null
                      ? PdfViewerDrawer(
                          pdfUrl: pdfUrl!,
                        )
                      : Container(),
                ),
              ),
            ),
          ),
        ));
  }

  Widget customDrawerIndicator() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Scaffold.of(context).openDrawer();
        },
        child: Container(
          width: 48, // Adjust size as needed
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            Icons.swipe,
            size: 32, // Adjust size as needed
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget buildTimeRemainingSection(int examDurationInSeconds) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.access_time,
                color: Colors.black,
              ),
              SizedBox(width: 8.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  'Time Remaining : ${_formatDuration(examDurationInSeconds)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _submitButtonPressed,
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: constraints.maxWidth < 400 ? 14.0 : 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green, // Text color
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth < 400 ? 12.0 : 20.0,
                      vertical: constraints.maxWidth < 400 ? 8.0 : 12.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> concatenateTextForQuestion(int questionNumber) async {
    List<String> textList = [];
    if (_questionPagesMap.containsKey(questionNumber)) {
      int pageCount = _questionPagesMap[questionNumber]!.length;
      for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        String pageText =
            await _recognizeTextForPage(questionNumber, pageIndex);
        textList.add(pageText);
      }
    }
    return textList.join(' ');
  }

  void _submitButtonPressed({bool isManual = true}) async {
    if (_isMounted) {
      if (isManual) {
        bool? confirmSubmit = await _showConfirmationDialog();
        if (confirmSubmit != null && confirmSubmit) {
          await _submitAnswers();
          timerExpiredMap[widget.subjectName] =
              true; // Set timerExpired to true
          if (_isMounted) {
            // Navigate back to the previous screen only if component is mounted
            Navigator.of(context).pop();
          }
        }
      } else {
        await _submitAnswers();
        timerExpiredMap[widget.subjectName] = true; // Set timerExpired to true
        if (_isMounted) {
          // Navigate back to the previous screen only if component is mounted
          Navigator.pop(context);
        }
      }
    }
    Navigator.pop(context);
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Submission'),
        content: Text('Are you sure you want to submit your answers?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAnswers() async {
    String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    await _saveButtonPressed(isManual: false);

    // // Fetch the reference answer URL
    // String referenceAnswerUrl = await _fetchReferenceAnswerUrl(widget.subjectName);

    // Submit answers along with the reference answer URL
    postData(
      userEmail: userEmail,
      subjectName: widget.subjectName,
    );
  }

  Future<void> _saveButtonPressed({bool isManual = true}) async {
    if (!mounted) return;

    String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    List<int> sortedQuestionNumbers = questionNumbers.toList()..sort();

    for (int questionNumber in sortedQuestionNumbers) {
      String questionText = await concatenateTextForQuestion(questionNumber);

      await uploadTextFileToFirestore(questionText, questionNumber, userEmail);
    }

    if (isManual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your answers have been saved.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your answers have been submitted.'),
        ),
      );
    }
  }

  Future<void> uploadTextFileToFirestore(
      String text, int questionNumber, String userEmail) async {
    try {
      print(userEmail);
      await FirebaseFirestore.instance
          .collection('TextFiles')
          .doc('${widget.subjectName}_${userEmail}')
          .set({'Answer_$questionNumber': text}, SetOptions(merge: true));
      print('Text file for Question $questionNumber uploaded successfully.');
    } catch (e) {
      print('Error uploading text file for Question $questionNumber: $e');
    }
  }

  Future<String> _recognizeTextForPage(
      int questionNumber, int pageIndex) async {
    try {
      DigitalInkRecognizer digitalInkRecognizer =
          DigitalInkRecognizer(languageCode: 'en');
      final candidates = await digitalInkRecognizer
          .recognize(_questionPagesMap[questionNumber]![pageIndex]);
      String recognizedText = candidates.isNotEmpty ? candidates[0].text : '';
      print(
          'Text recognized for Question $questionNumber, Page ${pageIndex + 1}: $recognizedText');
      return recognizedText;
    } catch (e) {
      print(
          'Error recognizing text for Question $questionNumber, Page ${pageIndex + 1}: $e');
      return '';
    }
  }

  String _formatDuration(int durationInSeconds) {
    Duration duration = Duration(seconds: durationInSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
