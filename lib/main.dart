import 'package:flutter/material.dart';
import 'package:ridesync/theme/app_theme.dart';
import 'package:ridesync/user/Registration.dart';

import 'package:ridesync/user/profile.dart';
import 'package:ridesync/vehicle%20owner/RegistrationOwner.dart';
import 'package:ridesync/vehicle%20owner/complaint.dart';
import 'package:ridesync/vehicle%20owner/feedback.dart';
import 'package:ridesync/user/home.dart';
import 'package:ridesync/user/liftservices.dart';
import 'package:ridesync/user/login.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CabSharing',
      theme: AppTheme.darkTheme,
      home: loginscreen(),
    );
  }
}
