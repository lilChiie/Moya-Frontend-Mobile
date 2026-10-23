import 'package:flutter/material.dart';
import '../features/splash/splash_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/auth/welcome_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/main_navigation/main_navigation_page.dart';
import '../features/destinations/destination_page.dart';
import '../features/destinations/destination_detail_page.dart';
import '../features/leaderboard/leaderboard_page.dart';
import '../features/notification/notification_page.dart';
import '../features/route_recommendation/route_recommendation_form_page.dart';
import '../features/route_recommendation/route_recommendation_page.dart';
import '../features/report/report_condition_page.dart';
import '../features/categories/categories_page.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String mainNav = '/main_nav';

  static const String destinations = '/destinations';
  static const String categories = '/categories';
  static const String leaderboard = '/leaderboard';
  static const String notification = '/notification';
  static const String routeForm = '/route_form';
  static const String reportCondition = '/report_condition';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashPage(),
      onboarding: (context) => const OnboardingPage(),
      welcome: (context) => const WelcomePage(),
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      mainNav: (context) => const MainNavigationPage(),
      destinations: (context) => const DestinationPage(),
      categories: (context) => const CategoriesPage(),
      '/destination_detail': (context) => const DestinationDetailPage(),
      leaderboard: (context) => const LeaderboardPage(),
      notification: (context) => const NotificationPage(),
      routeForm: (context) => const RouteRecommendationFormPage(),
      '/route_recommendation_form': (context) => const RouteRecommendationFormPage(),
      '/route_recommendation': (context) => const RouteRecommendationPage(),
      reportCondition: (context) => const ReportConditionPage(),
    };
  }
}
