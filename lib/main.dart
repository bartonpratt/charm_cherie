import 'package:charm_cherie/provider.dart';
import 'package:charm_cherie/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'chat_screen.dart';

void main() {

  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Nessa's AI",
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark, seedColor: Colors.blue),
          useMaterial3: true,
          // textTheme: GoogleFonts.openSansTextTheme(Theme.of(context).textTheme)
          //     .apply(bodyColor: Colors.white,)
          //     .copyWith(
          //   bodyLarge: const TextStyle(color: bodyTextColor),
          //   bodyMedium: const TextStyle(color: bodyTextColor),
          // ),
        ),
        home: SplashScreen());
  }
}
