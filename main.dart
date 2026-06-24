import 'package:flutter/material.dart';

import 'screens/upload_screen.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedicalTranscriberApp());
}

class MedicalTranscriberApp extends StatelessWidget {
  const MedicalTranscriberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المُفرِّغ الطبي',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const UploadScreen(),
    );
  }
}
