import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> postData(
    {required String userEmail, required String subjectName}) async {
  try {
    // Fetch user data from Firestore
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      // Extract name, roll, and emailID from the user data
      DocumentSnapshot userData = userSnapshot.docs.first;
      String name = userData['name'];
      String roll = userData['regNo'];
      String emailID = userEmail;

      // Fetch number of questions for the subject
      DocumentSnapshot subjectSnapshot = await FirebaseFirestore.instance
          .collection('Subjects')
          .doc(subjectName)
          .get();

      if (subjectSnapshot.exists) {
        int numberOfQuestions = subjectSnapshot['numberOfQuestions'];

        // Print the number of questions fetched
        print('Number of questions fetched: $numberOfQuestions');

        // Fetch answers from TextFiles collection
        DocumentSnapshot textFileSnapshot = await FirebaseFirestore.instance
            .collection('TextFiles')
            .doc('${subjectName}_$userEmail')
            .get();

        if (textFileSnapshot.exists) {
          // Initialize a list to store answers
          List<String> answers = [];

          // Loop through all answer fields and add them to the list
          for (int i = 1; i <= numberOfQuestions; i++) {
            String answer = textFileSnapshot['Answer_$i'];
            if (answer != null) {
              answers.add(answer);
            }
          }

          // Fetch reference answers for the subject
          DocumentSnapshot referenceAnswersSnapshot = await FirebaseFirestore
              .instance
              .collection('Reference Answers')
              .doc(subjectName)
              .get();

          if (referenceAnswersSnapshot.exists) {
            // Initialize a list to store reference answers
            List<String> referenceAnswers = [];

            // Loop through all reference answer fields and add them to the list
            for (int i = 1; i <= numberOfQuestions; i++) {
              String referenceAnswer = referenceAnswersSnapshot['Answer_$i'];
              if (referenceAnswer != null) {
                referenceAnswers.add(referenceAnswer);
              }
            }

            // Construct the data map
            Map<String, dynamic> data = {
              "first": answers, // Send the list of user's answers
              "second": referenceAnswers, // Send the list of reference answers
              "name": name,
              "roll": roll,
              "emailID": emailID,
            };

            // Convert data to JSON
            String jsonData = jsonEncode(data);

            // Print the content of the JSON data
            print('JSON data to be sent:');
            print(jsonData);

            // Make POST request
            final response = await http.post(
              Uri.parse("http://192.168.69.153:8888/examinator"),
              headers: <String, String>{
                'Content-Type': 'application/json',
                // Add any headers if required
              },
              body: jsonData,
            );

            // Check if request was successful
            if (response.statusCode == 200) {
              // Parse the response JSON
              Map<String, dynamic> result = jsonDecode(response.body);

              // Extract total marks from the response
              int totalMarks = result['total_marks'];

              // Store total marks into Firestore
              await FirebaseFirestore.instance
                  .collection('marks')
                  .doc(subjectName)
                  .set(
                      {
                    roll: totalMarks,
                    // Add additional fields as needed
                  },
                      SetOptions(
                          merge:
                              true)); // Merge with existing document if it exists

              print('Total marks stored in Firestore: $totalMarks');
            } else {
              // Request failed
              print('Post request failed with status: ${response.statusCode}');
              print('Response: ${response.body}');
            }
          } else {
            print('Reference answers not found for subject: $subjectName');
          }
        } else {
          print('Text file not found for user: $userEmail');
        }
      } else {
        print('Subject not found: $subjectName');
      }
    } else {
      // No user data found for the provided email
      print('No user data found for email: $userEmail');
    }
  } catch (e) {
    // Exception occurred during request
    print('Exception during post request: $e');
  }
}
