import 'package:business_app/tools/Database_helper.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  const Register({super.key});
  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  bool hidden = true;
  final formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _rPasswordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // appBar:AppBar(
      //   title: Text('Register',
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
                        'To continue using this app, please Register',
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
                                  controller: _shopNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Name of Shop',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter the name of your shop'
                                      : null,
                                ),
                                SizedBox(height: 20),
                                TextFormField(
                                  controller: _shopAddressController,
                                  decoration: InputDecoration(
                                    labelText: 'Address of Shop',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter the address of your shop'
                                      : null,
                                ),
                                SizedBox(height: 20),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Please enter your email';
                                    } else if (!value.contains('@') ||
                                        (!value.contains('.'))) {
                                      return 'Please enter a valid email';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                                SizedBox(height: 20),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Phone',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Please enter your phone number';
                                    } else if (value.length < 10) {
                                      return 'Phone number must be at least 10 digits';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                                SizedBox(height: 20),
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
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
                                    if (value!.isEmpty) {
                                      return 'Please enter a password';
                                    } else if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                                SizedBox(height: 20),
                                TextFormField(
                                  controller: _rPasswordController,
                                  obscureText: hidden,
                                  obscuringCharacter: '*',
                                  decoration: InputDecoration(
                                    labelText: 'Re-Type Password',
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
                                    if (value!.isEmpty) {
                                      return 'Please re-enter your password';
                                    } else if (value !=
                                        _passwordController.text) {
                                      return 'Passwords do not match';
                                    } else {
                                      return null;
                                    }
                                  },
                                ),
                                SizedBox(height: 20),
                                _authButtons(
                                  context,
                                  "Register",
                                  "assets/images/unlock.png",
                                  Colors.blue[900],
                                  "Login",
                                  _registerUser,
                                ),
                                SizedBox(height: 10),
                                _authButtons(
                                  context,
                                  "Register with Gmail",
                                  "assets/images/gmail.png",
                                  Colors.blue[900],
                                  "Dashboard",
                                  _registerUser,
                                ),
                                SizedBox(height: 10),
                                _authButtons(
                                  context,
                                  "Register with Facebook",
                                  "assets/images/facebook.png",
                                  Colors.blue[900],
                                  "Dashboard",
                                  _registerUser,
                                ),
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
    route,
    Future<bool> Function() nextAction,
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
            final success = await nextAction();
            if (success) {
              // ignore: use_build_context_synchronously
              Navigator.pushNamed(context, "/$route");
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Registration failed',
                    style: TextStyle(color: Colors.red),
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            }
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

  Future<bool> _registerUser() async {
    if (formKey.currentState!.validate()) {
      Map<String, dynamic> user = {
        'shopname': _shopNameController.text,
        'shopaddress': _shopAddressController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'username': _usernameController.text,
        'password': _passwordController.text,
      };
      int id = await DatabaseHelper.instance.insertUser(user);
      SnackBar snackBar = SnackBar(
        content: Text('User registered with ID: $id'),
        duration: Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      formKey.currentState!.reset();
      _shopNameController.clear();
      _shopAddressController.clear();
      _emailController.clear();
      _phoneController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _rPasswordController.clear();
      return id > 0 ? true : false;
    }
    return false;
  }
}
