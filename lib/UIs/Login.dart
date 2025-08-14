import 'package:business_app/tools/Database_helper.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool hidden = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // appBar:AppBar(
      //   title: Text('Login',
      //   style: TextStyle(fontSize: 24, color: Colors.blue[900],fontWeight: FontWeight.bold),),
      // ),
      body: Stack(
        children: [
          Container(
            // width: double.infinity,
            // height: double.infinity,
            color: Colors.blue[900],
            child: Container(
              width: double.infinity,
              height: double.infinity,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(150, 250),
                  bottomRight: Radius.elliptical(100, 250),
                ),
              ),

              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'To continue using this app, please login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.only(left: 30, right: 30),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 20,
                          ),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter your username'
                                      : null,
                                ),
                                SizedBox(height: 20),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: hidden,
                                  obscuringCharacter: '*',
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),

                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          hidden = !hidden;
                                        });
                                      },
                                      icon: Icon(
                                        hidden
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 20),
                                _authButtons(
                                  context,
                                  "Login",
                                  "assets/images/unlock.png",
                                  Colors.blue[900],
                                  authenticateUser,
                                ),
                                // SizedBox(height: 10),
                                // _authButtons(
                                //   context,
                                //   "Login with Gmail",
                                //   "assets/images/gmail.png",
                                //   Colors.blue[900],
                                //   "Dashboard",
                                // ),
                                // SizedBox(height: 10),
                                // _authButtons(
                                //   context,
                                //   "Login with Facebook",
                                //   "assets/images/facebook.png",
                                //   Colors.blue[900],
                                //   "Dashboard",
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _authButtons(
    BuildContext context,
    buttonName,
    imagePath,
    color,
    Function() nextAction,
  ) {
    return SizedBox(
      width: 500,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: color, // Blue background for entire container
          borderRadius: BorderRadius.circular(32), // Rounded corners
        ),
        child: ElevatedButton(
          onPressed: () async {
            await nextAction();
            // Call the next action function
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, // Makes button transparent
            shadowColor: Colors.transparent, // Removes shadow
            padding: EdgeInsets.zero, // Removes default padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32), // Match container radius
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Makes row take minimum space
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: Image.asset(imagePath, width: 48, height: 48),
              ),
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: Text(
                  buttonName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> authenticateUser() async {
    if (formKey.currentState!.validate()) {
      String username = _usernameController.text;
      String password = _passwordController.text;
      bool isAuthenticated = await DatabaseHelper.instance.authenticateUser(
        username,
        password,
      );
      // Simulate a successful login for demonstration purposes
      if (isAuthenticated) {
        Navigator.pushNamed(context, '/Dashboard');
        // Authentication successful
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.white,
            content: Center(
              child: Text(
                "Invalid username or password",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
        return false; // Authentication failed
      }
    }
    return true;
  }
}
