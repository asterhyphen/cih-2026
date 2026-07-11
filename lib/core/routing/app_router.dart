import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/network_simulator/presentation/network_simulator_page.dart';
import '../../features/nfc_capture/presentation/nfc_capture_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/specialist_view/presentation/specialist_page.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const nfcCapture = '/nfc-capture';
  static const networkSimulator = '/network-simulator';
  static const specialist = '/specialist';
  static const settings = '/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(authProvider).isAuthenticated;

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isPublicRoute =
          path == AppRoutes.login ||
          path == AppRoutes.register ||
          path == AppRoutes.onboarding;

      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated &&
          (path == AppRoutes.login ||
              path == AppRoutes.register ||
              path == AppRoutes.onboarding)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.nfcCapture,
        builder: (context, state) => const NfcCapturePage(),
      ),
      GoRoute(
        path: AppRoutes.networkSimulator,
        builder: (context, state) => const NetworkSimulatorPage(),
      ),
      GoRoute(
        path: AppRoutes.specialist,
        builder: (context, state) => const SpecialistPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
