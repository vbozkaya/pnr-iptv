import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/iptv_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/tv_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/user_selection_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize StorageService
  await StorageService.init();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Provider'ları oluştur
  final iptvProvider = IptvProvider();
  final userProvider = UserProvider();
  await userProvider.initializeWithIptvProvider(iptvProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<IptvProvider>.value(value: iptvProvider),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PNR IPTV',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final storageService = StorageService();
      final isLoggedIn = await storageService.isLoggedIn();
      
      if (mounted) {
        if (isLoggedIn) {
          // Kullanıcı giriş yapmış, ana sayfaya yönlendir
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DeviceSpecificHome()),
          );
        } else {
          // Kullanıcı giriş yapmamış, kullanıcı seçim sayfasına yönlendir
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => UserSelectionScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => UserSelectionScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.black],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.tv,
                  size: 60,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'PNR IPTV',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeviceSpecificHome extends StatefulWidget {
  const DeviceSpecificHome({super.key});

  @override
  State<DeviceSpecificHome> createState() => _DeviceSpecificHomeState();
}

class _DeviceSpecificHomeState extends State<DeviceSpecificHome> {
  bool _isTv = false;

  @override
  void initState() {
    super.initState();
    _checkDeviceType();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final iptvProvider = Provider.of<IptvProvider>(context, listen: false);
      await userProvider.loadActiveUserPlaylist(iptvProvider: iptvProvider);
    });
  }

  Future<void> _checkDeviceType() async {
    try {
      // Check if this is an Android TV device
      const platform = MethodChannel('device_info');
      final result = await platform.invokeMethod('isAndroidTv');
      if (mounted) {
        setState(() {
          _isTv = result == true;
        });
      }
    } catch (e) {
      // Fallback: check screen size to determine if it's likely a TV
      if (mounted) {
        final mediaQuery = MediaQuery.of(context);
        final screenSize = mediaQuery.size;
        setState(() {
          _isTv = screenSize.width > 1200 || screenSize.height > 800;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check screen size as a fallback method
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isLargeScreen = screenSize.width > 1200 || screenSize.height > 800;

    if (_isTv || isLargeScreen) {
      return const TvHomeScreen();
    } else {
      return const HomeScreen();
    }
  }
}
