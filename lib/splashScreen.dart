import 'package:flutter/material.dart';
import 'package:business_app/tools/Database_helper.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/splash.jpg"),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 600),
            child: Center(
              child: SizedBox(
                width: 300,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    checkUserExist(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    "Get Started",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> checkUserExist(BuildContext context) async {
    final hasUser = await DatabaseHelper.instance.hasAnyuser();
    if (!hasUser) {
      Future.delayed(Duration.zero, () {
        // ignore: use_build_context_synchronously
        Navigator.pushNamed(context, '/Register');
      });
    } else {
      Future.delayed(Duration.zero, () {
        // ignore: use_build_context_synchronously
        Navigator.pushNamed(context, '/Login');
      });
    }
    return hasUser;
  }
}
