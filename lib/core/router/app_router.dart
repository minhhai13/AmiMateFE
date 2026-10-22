import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/chat_log/presentation/screens/chat_history_screen.dart';
import '../../features/chat_log/presentation/screens/chat_conversation_screen.dart';
import '../../features/device/presentation/screens/claim_device_screen.dart';
import '../../features/device/presentation/screens/dashboard_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

abstract final class AppRouteNames {
  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';
  static const dashboard = 'dashboard';
  static const claimDevice = 'claim-device';
  static const chatHistory = 'chat-history';
  static const chatConversation = 'chat-conversation';
  static const settings = 'settings';
}

abstract final class AppRoutePaths {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const claimDevice = '/devices/claim';
  static const chatHistory = '/devices/:deviceId/logs';
  static const chatConversation = '/devices/:deviceId/logs/:chatId';
  static const settings = '/settings';
}

GoRouter createAppRouter({Ref? ref}) {
  return GoRouter(
    initialLocation: AppRoutePaths.splash,
    redirect: (context, state) {
      if (ref == null) return null;

      final sessionStatus = ref.read(authControllerProvider).status;
      final location = state.matchedLocation;
      final isPublicRoute =
          location == AppRoutePaths.splash ||
          location == AppRoutePaths.login ||
          location == AppRoutePaths.register;

      if (sessionStatus == AuthSessionStatus.checking ||
          sessionStatus == AuthSessionStatus.error) {
        return location == AppRoutePaths.splash ? null : AppRoutePaths.splash;
      }

      if (sessionStatus == AuthSessionStatus.unauthenticated) {
        if (location == AppRoutePaths.splash) return AppRoutePaths.login;
        return isPublicRoute ? null : AppRoutePaths.login;
      }

      if (isPublicRoute) return AppRoutePaths.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutePaths.splash,
        name: AppRouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        name: AppRouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.register,
        name: AppRouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.dashboard,
        name: AppRouteNames.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.claimDevice,
        name: AppRouteNames.claimDevice,
        builder: (context, state) => const ClaimDeviceScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.chatHistory,
        name: AppRouteNames.chatHistory,
        builder: (context, state) =>
            ChatHistoryScreen(deviceId: state.pathParameters['deviceId']!),
      ),
      GoRoute(
        path: AppRoutePaths.chatConversation,
        name: AppRouteNames.chatConversation,
        builder: (context, state) => ChatConversationScreen(
          deviceId: state.pathParameters['deviceId']!,
          chatId: state.pathParameters['chatId']!,
        ),
      ),
      GoRoute(
        path: AppRoutePaths.settings,
        name: AppRouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter(ref: ref);
  ref.listen(authControllerProvider, (previous, next) {
    router.refresh();
  });
  ref.onDispose(router.dispose);
  return router;
});
