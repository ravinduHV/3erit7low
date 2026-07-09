import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'injection/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/identity_mode_page.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/progress/presentation/bloc/progress_bloc.dart';
import 'features/progress/domain/entities/progress_entities.dart';
import 'features/progress/presentation/pages/awards_list_page.dart';
import 'features/progress/presentation/pages/award_detail_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/pages/privacy_settings_page.dart';
import 'features/admin/presentation/pages/admin_syllabus_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>(),
        ),
        BlocProvider<ProgressBloc>(
          create: (context) => di.sl<ProgressBloc>(),
        ),
      ],
      child: const AppRouter(),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({Key? key}) : super(key: key);

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/identity-mode',
          builder: (context, state) {
            final params = state.extra as Map<String, dynamic>;
            return IdentityModePage(
              email: params['email'] as String,
              password: params['password'] as String,
            );
          },
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: '/awards-list',
          builder: (context, state) => const AwardsListPage(),
        ),
        GoRoute(
          path: '/award-detail',
          builder: (context, state) => AwardDetailPage(
            award: state.extra as AwardProgressEntity,
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: '/privacy-settings',
          builder: (context, state) => const PrivacySettingsPage(),
        ),
        GoRoute(
          path: '/admin-syllabus',
          builder: (context, state) => const AdminSyllabusPage(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Map active scout section dynamically for theme configuration
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String? sectionId;
        if (state is Authenticated) {
          sectionId = state.user.sectionId;
        } else if (state is OnboardingRequired) {
          sectionId = state.user.sectionId;
        }

        return MaterialApp.router(
          title: 'MeritFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(context, isDark: false, sectionId: sectionId),
          darkTheme: AppTheme.getTheme(context, isDark: true, sectionId: sectionId),
          themeMode: ThemeMode.system,
          routerConfig: _router,
        );
      },
    );
  }
}
