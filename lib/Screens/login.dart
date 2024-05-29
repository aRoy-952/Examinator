import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../User Model/model.dart';
import 'forgot.dart';
import '../Navigation Control/home.dart';
import 'register.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isObscure3 = true;
  bool visible = false;
  final _formkey = GlobalKey<FormState>();
  final TextEditingController regNoController =
      TextEditingController(); // Change to regNoController
  final TextEditingController passwordController = TextEditingController();
  late final AnimationController _controller;

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the AnimationController
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: Duration(seconds: 5), vsync: this);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              child: Stack(
                children: <Widget>[
                  Positioned(
                    child: FadeInUp(
                      duration: Duration(milliseconds: 1300),
                      child: Container(
                        margin: EdgeInsets.only(top: 100),
                        child: Center(
                          child: Text(
                            "Login",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 80,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                children: <Widget>[
                  FadeInUp(
                    duration: Duration(milliseconds: 1800),
                    child: Container(
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                      ),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          children: <Widget>[
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return Lottie.asset(
                                  'assets/images/Animation - 1709066773356 (1).json',
                                  height: 500,
                                  width: 500,
                                  controller: _controller,
                                );
                              },
                            ),
                            Container(
                              padding: EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(color: Colors.white))),
                              child: TextFormField(
                                controller:
                                    regNoController, // Use regNoController
                                decoration: InputDecoration(
                                  fillColor: Colors.white,
                                  filled: true,
                                  enabled: true,
                                  labelText:
                                      'Registration Number', // Change label text
                                  prefixIcon:
                                      const Icon(Icons.person), // Change icon
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return "Registration Number cannot be empty"; // Change validation message
                                  }
                                  // Add additional validation if needed
                                  return null;
                                },
                                keyboardType: TextInputType
                                    .number, // Set keyboard type to number
                                maxLength: 13,
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              padding: EdgeInsets.all(0),
                              child: TextFormField(
                                controller: passwordController,
                                obscureText: _isObscure3,
                                decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                    icon: Icon(_isObscure3
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () {
                                      setState(() {
                                        _isObscure3 = !_isObscure3;
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  labelText: 'Password',
                                  enabled: true,
                                  prefixIcon: const Icon(Icons.lock),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                validator: (value) {
                                  RegExp regex = RegExp(r'^.{6,}$');
                                  if (value!.isEmpty) {
                                    return "Password cannot be empty";
                                  }
                                  if (!regex.hasMatch(value)) {
                                    return ("Please enter valid password min. 6 character");
                                  } else {
                                    return null;
                                  }
                                },
                                onSaved: (value) {
                                  passwordController.text = value!;
                                },
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const Forgotpass(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      signIn(
                          regNoController.text,
                          passwordController
                              .text); // Pass registration number instead of email
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10))),
                      backgroundColor: Colors.black,
                      elevation: 20.0,
                      minimumSize: Size(double.infinity, 52),
                    ),
                    child: Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 180),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Register(),
                            ),
                          );
                        },
                        child: Text(
                          'Register now',
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void signIn(String regNo, String password) async {
    if (_formkey.currentState!.validate()) {
      try {
        // Fetch user data from Firestore based on the provided registration number
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('regNo', isEqualTo: regNo)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // User with provided registration number exists, authenticate using password
          DocumentSnapshot userDoc = querySnapshot.docs.first;
          UserModel userModel =
              UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
          UserCredential userCredential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: userModel.email!,
            password: password,
          );

          // Successfully authenticated, navigate to HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(),
            ),
          );
        } else {
          // No user found for the provided registration number
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No user found for that registration number.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;

        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found for that registration number.';
            break;
          case 'wrong-password':
            errorMessage = 'Wrong password provided for that user.';
            break;
          default:
            errorMessage = 'Error: ${e.message ?? 'Authentication failed.'}';
        }

        // Show a Snackbar with the error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
