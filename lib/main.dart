import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'theme/prime_theme.dart';
import 'services/state_service.dart';
import 'services/audio_service.dart';
import 'services/voice_service.dart';
import 'services/debug_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture all Flutter errors into DebugService
  FlutterError.onError = (details) {
    DebugService.instance.error('FLUTTER', '${details.exceptionAsString()}\n${details.stack ?? ''}');
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    DebugService.instance.error('DART', '$error\n$stack');
    return true;
  };

  await WindowManager.instance.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1400, 900),
    minimumSize: Size(1024, 640),
    center: true,
    title: 'PRIME',
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: true,
  );

  await WindowManager.instance.waitUntilReadyToShow(windowOptions, () async {
    await WindowManager.instance.show();
    await WindowManager.instance.focus();
  });

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await AudioService.instance.initialize();
  await VoiceService.instance.initialize();

  runApp(const PrimeApp());
}

class PrimeApp extends StatelessWidget {
  const PrimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StateService()..initialize(),
      child: MaterialApp(
        title: 'PRIME',
        debugShowCheckedModeBanner: false,
        theme: PrimeTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      ),
    );
  }
}
