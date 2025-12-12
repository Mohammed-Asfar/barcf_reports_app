import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'core/auth/auth_service.dart';
import 'features/reports/providers/reports_provider.dart';
import 'features/admin/providers/user_provider.dart';
import 'features/auth/login_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  doWhenWindowReady(() {
    const initialSize = Size(1000, 600);
    appWindow.size = initialSize;
    appWindow.minSize = const Size(1000, 600);
    appWindow.alignment = Alignment.center;
    appWindow.title = "BARCF Reports";
    appWindow.show();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'BARCF Reports',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
        // Use builder to wrap ALL screens with WindowTitleBar
        builder: (context, child) {
          return WindowTitleBar(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}

// Custom Window Title Bar
class WindowTitleBar extends StatelessWidget {
  final Widget child;
  const WindowTitleBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Add top padding to avoid overlap with title bar
        Container(
          padding: const EdgeInsets.only(top: 20),
          color: Theme.of(context).scaffoldBackgroundColor,
          child: child,
        ),
        WindowTitleBarBox(
          child: SizedBox(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: MoveWindow(), // Makes the title bar draggable
                ),
                const WindowButtons(), // Custom window buttons
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Window Button Colors
final buttonColors = WindowButtonColors(
  iconNormal: Colors.white,
  mouseOver: AppTheme.darkTheme.primaryColor,
  mouseDown: AppTheme.darkTheme.primaryColor.withOpacity(0.7),
  iconMouseOver: Colors.white,
  iconMouseDown: Colors.white,
);

// Custom Window Buttons
class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(
          colors: buttonColors,
          animate: true,
        ),
        MaximizeWindowButton(
          colors: buttonColors,
          animate: true,
        ),
        CloseWindowButton(
          colors: buttonColors,
          animate: true,
        ),
      ],
    );
  }
}
