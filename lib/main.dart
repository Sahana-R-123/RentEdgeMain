import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_try02/navigation/app_routes.dart';
import 'package:flutter_try02/theme/app_theme.dart';
import 'package:flutter_try02/providers/favorite_provider.dart';
import 'package:flutter_try02/providers/profile_provider.dart';
import 'package:flutter_try02/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FavoriteProvider()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const RentEdgeApp(),
    ),
  );
}

Future<void> requestPermissions() async {
  if (kIsWeb) {
    print('Storage permission not needed on web.');
    return;
  }

  var cameraStatus = await Permission.camera.request();
  if (cameraStatus.isDenied) {
    print("Camera permission denied");
  }

  var storageStatus = await Permission.storage.request();
  if (storageStatus.isDenied) {
    print("Storage permission denied");
  }
}

class RentEdgeApp extends StatelessWidget {
  const RentEdgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RentEdge',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash, // Changed from home to splash
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}