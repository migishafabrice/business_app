import 'package:business_app/UIs/Dashboard.dart';
import 'package:business_app/UIs/Login.dart';
import 'package:business_app/UIs/Register.dart';
import 'package:business_app/splashScreen.dart';
import 'package:business_app/tools/inventoryProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // DateTime now = DateTime.now();
    // String dayName = [
    //   'Monday',
    //   'Tuesday',
    //   'Wednesday',
    //   'Thursday',
    //   'Friday',
    //   'Saturday',
    //   'Sunday',
    // ][now.weekday - 1];
    // String formattedDate =
    //     "${now.month}/${now.day}/${now.year}";
    // Get formatted dat
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => InventoryProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Business App',
        // theme: ThemeData(primarySwatch: Colors.blue),
        home: SplashScreen(),
        routes: {
          '/Dashboard': (context) => Dashboard(),
          '/Login': (context) => Login(),
          '/Register': (context) => Register(),
        },
      ),
    );
  }
}
