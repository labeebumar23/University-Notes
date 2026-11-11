import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_semesters_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/semester_subjects_screen.dart';
import 'screens/subject_workspace_screen.dart';
import 'screens/recorder_screen.dart';
import 'screens/settings_screen.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedTheme = await StorageService.instance.getThemeMode();
  themeModeNotifier.value = savedTheme;

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: savedTheme == ThemeMode.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: savedTheme == ThemeMode.dark ? const Color(0xFF121212) : const Color(0xFFFAFAEF),
      systemNavigationBarIconBrightness: savedTheme == ThemeMode.dark ? Brightness.light : Brightness.dark,
    ),
  );
  runApp(const UniNotesApp());
}

class UniNotesApp extends StatelessWidget {
  const UniNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'UniNotes',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const _AppRootLauncher(),
          routes: {
            '/onboarding': (context) => const OnboardingScreen(),
            '/home': (context) => const HomeSemestersScreen(),
            '/subjects': (context) => const SemesterSubjectsScreen(),
            '/workspace': (context) => const SubjectWorkspaceScreen(),
            '/recorder': (context) => const RecorderScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}

class _AppRootLauncher extends StatefulWidget {
  const _AppRootLauncher();

  @override
  State<_AppRootLauncher> createState() => _AppRootLauncherState();
}

class _AppRootLauncherState extends State<_AppRootLauncher> {
  bool _isLoading = true;
  bool _isOnboarded = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final onboarded = await StorageService.instance.isOnboarded();
    if (mounted) {
      setState(() {
        _isOnboarded = onboarded;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF004AAD)),
          ),
        ),
      );
    }

    if (_isOnboarded) {
      return const HomeSemestersScreen();
    } else {
      return const OnboardingScreen();
    }
  }
}
