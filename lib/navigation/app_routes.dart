import 'package:flutter/material.dart';
import 'package:flutter_try02/screens/favorites_screen.dart';
import 'package:flutter_try02/screens/edit_profile_screen.dart';
import 'package:flutter_try02/screens/home_screen.dart';
import 'package:flutter_try02/screens/chat_screen.dart';
import 'package:flutter_try02/screens/login_screen.dart';
import 'package:flutter_try02/screens/signup_screen.dart';
import 'package:flutter_try02/screens/dashboard_screen.dart';
import 'package:flutter_try02/screens/phone_number_screen.dart';
import 'package:flutter_try02/screens/otp_verification_screen.dart';
import 'package:flutter_try02/screens/profile_screen.dart';
import 'package:flutter_try02/screens/chat_detail_screen.dart';
import 'package:flutter_try02/screens/success_screen.dart';
import 'package:flutter_try02/screens/category_screen.dart';
import 'package:flutter_try02/screens/sell_product_screen.dart';
import 'package:flutter_try02/screens/verification_screen.dart';
import 'package:flutter_try02/screens/product_upload_success_screen.dart';
import 'package:flutter_try02/screens/report_issue_screen.dart';
import 'package:flutter_try02/screens/splash_screen.dart';
import 'package:flutter_try02/screens/rental_details_screen.dart';
import 'package:flutter_try02/screens/user_selection_screen.dart';
import 'package:flutter_try02/screens/requests_screen.dart';


class AppRoutes {
  // Route names constants (unchanged from your original)
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verification = '/verification';
  static const String dashboard = '/dashboard';
  static const String phone = '/phone';
  static const String otp = '/otp';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String chatDetail = '/chat-detail';
  static const String success = '/success';
  static const String category = '/category';
  static const String chat = '/chat';
  static const String sellProduct = '/sell-product';
  static const String uploadSuccess = '/upload-success';
  static const String reportIssue = '/report-issue';
  static const String rentalDetails = '/rental-details';
  static const String selectUser = '/select-user';
  static const String requests = '/requests';


  // Enhanced routes with proper type safety
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    verification: (context) => const VerificationScreen(),
    dashboard: (context) => const DashboardScreen(),
    phone: (context) => const PhoneNumberScreen(),
    otp: (context) => const OtpVerificationScreen(),
    favorites: (context) => const FavoritesScreen(),
    profile: (context) => const ProfileScreen(),
    editProfile: (context) => const EditProfileScreen(),
    chat: (context) => const ChatScreen(),
    category: (context) => const CategoryScreen(),
    uploadSuccess: (context) => const ProductUploadSuccessScreen(),
    reportIssue: (context) => ReportIssueScreen(),
    selectUser: (context) => const UserSelectionScreen(),
    requests: (context) => const RequestsScreen(),
  };

  // Type-safe route generator with chat enhancements
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case chatDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            currentUserId: args['currentUserId'] as String,
            receiverId: args['receiverId'] as String,
            receiverName: args['receiverName'] as String,
            receiverImage: args['receiverImage'] as String,
            chatType: args['chatType'] as String? ?? 'all', // Default to 'all' if not specified
          ),
        );

      case success:
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (context) => SuccessScreen(
            successMessage: args['successMessage']!,
            redirectRoute: args['redirectRoute']!,
          ),
        );

      case sellProduct:
        final category = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => SellProductScreen(initialCategory: category),
        );

      case rentalDetails:
        final rentalData = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (context) => RentalDetailsScreen(rentalData: rentalData),
        );

      default:
        return _errorRoute(settings.name);
    }
  }

  // Navigation methods with improved type safety
  static Future<T?> push<T extends Object?>(
      BuildContext context,
      String routeName, {
        Object? arguments,
      }) {
    _validateRoute(routeName);
    return Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
      BuildContext context,
      String routeName, {
        Object? arguments,
        TO? result,
      }) {
    _validateRoute(routeName);
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static Future<T?> pushAndRemoveUntil<T extends Object?>(
      BuildContext context,
      String routeName, {
        Object? arguments,
        bool Function(Route<dynamic>)? predicate,
      }) {
    _validateRoute(routeName);
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  // Helper methods
  static Route<dynamic> _errorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(
          child: Text('Page not found: ${routeName ?? 'unknown'}'),
        ),
      ),
    );
  }

  static void _validateRoute(String routeName) {
    final validRoutes = [
      splash, home, login, signup, verification, dashboard, phone, otp,
      favorites, profile, editProfile, chatDetail, success, category,
      chat, sellProduct, uploadSuccess, reportIssue, rentalDetails,
    ];

    if (!validRoutes.contains(routeName)) {
      throw ArgumentError('Invalid route name: $routeName');
    }
  }

  // Existing pop methods
  static void pop<T extends Object?>(BuildContext context, [T? result]) =>
      Navigator.pop(context, result);

  static bool canPop(BuildContext context) => Navigator.canPop(context);
}
