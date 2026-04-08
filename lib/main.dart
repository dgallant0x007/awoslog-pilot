import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/cockpit_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const AwoslogApp());
}

class AwoslogApp extends StatelessWidget {
  const AwoslogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AWOSLOG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CockpitScreen(),
    );
  }
}
