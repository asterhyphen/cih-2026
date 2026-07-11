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

final appRouterProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final path = state.matchedLocation;
      final isPublicRoute =
          path == '/login' || path == '/register' || path == '/onboarding';

      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      if (isAuthenticated &&
          (path == '/login' || path == '/register' || path == '/onboarding')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/nfc-capture',
        builder: (context, state) => const NfcCapturePage(),
      ),
      GoRoute(
        path: '/network-simulator',
        builder: (context, state) => const NetworkSimulatorPage(),
      ),
      GoRoute(
        path: '/specialist',
        builder: (context, state) => const SpecialistPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
