import 'package:examinator/Student%20Dashboard/subjectList.dart';
import 'package:flutter/material.dart';

class InstructionToCanvass extends StatefulWidget {
  final int numberOfQuestions; // Define the parameter here

  const InstructionToCanvass({Key? key, required this.numberOfQuestions})
      : super(key: key);

  @override
  State<InstructionToCanvass> createState() => _InstructionToCanvassState();
}

class _InstructionToCanvassState extends State<InstructionToCanvass> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Instructions",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.indigo[50],
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Instructions:",
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _instructionItem(
                    "By tapping on the continue button, you will be directed to the page containing list of subjects"),
                _instructionItem(
                    "Tapping on the subject button will direct you to that subject exam"),
                _instructionItem(
                    "A page will open containing separate buttons for each question"),
                _instructionItem(
                    "The students have to handwrite their answers using the stylus provided"),
                _instructionItem(
                    "The answer for each question should be written under that particular question's button only; otherwise, the answer for any other question in the canvas of other questions would result in the saving of the answer under the wrong question and it would affect the marking of the student"),
                _instructionItem(
                    "The students can view the question paper either by tapping on the finger slide button on the top left corner or by sliding right from the left edge of the screen"),
              ],
            ),
            SizedBox(height: 20.0),
            Row(
              children: [
                Checkbox(
                  value: isChecked,
                  onChanged: (value) {
                    setState(() {
                      isChecked = value!;
                    });
                  },
                ),
                Text("I have read the instructions."),
              ],
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: isChecked
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SubjectListPage(), // Pass the parameter here
                        ),
                      );
                    }
                  : null,
              child: Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instructionItem(String instruction) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(fontSize: 16.0),
          ),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(fontSize: 16.0),
            ),
          ),
        ],
      ),
    );
  }
}
