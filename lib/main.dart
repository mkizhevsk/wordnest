import 'package:flutter/material.dart';
import 'package:wordnest/services/preferences_service.dart';
import 'package:wordnest/screens/contacts.dart';
import 'package:wordnest/screens/cards.dart';
import 'package:wordnest/screens/others.dart';
import 'package:wordnest/services/card_sync_service.dart';
import 'package:wordnest/screens/login_screen.dart';
import 'package:logging/logging.dart';
import 'package:wordnest/services/app_initializer.dart';

void main() {
  //_setupLogging();
  runApp(const MyApp());
}

void _setupLogging() {
  Logger.root.level = Level.ALL;

  Logger.root.onRecord.listen((LogRecord rec) {
    Logger.root.info(
        '${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Use the PreferencesService to check if it's the first launch
  Future<bool> _isFirstLaunch() async {
    final preferencesService = PreferencesService();
    return await preferencesService.isFirstLaunch();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<bool>(
        future: _isFirstLaunch(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error occurred"));
          } else if (snapshot.hasData && snapshot.data == true) {
            // If it's the first launch, navigate to the LoginScreen
            return const LoginScreen();
          } else {
            // If it's not the first launch, navigate directly to MyHomePage
            return const MyHomePage();
          }
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int _currentIndex;
  final CardSyncService cardSyncService = CardSyncService();

  List<Widget> body = [
    const CardTab(),
    const ContactTab(),
    const OtherTab(),
  ];

  @override
  void initState() {
    super.initState();
    print('initState of MyHomePage');
    _currentIndex = 0;

    // Schedule the method to run after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppInitializer.runAfterStart(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: body[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
        },
        items: const [
          BottomNavigationBarItem(
            label: 'Cards',
            icon: Icon(Icons.description),
          ),
          BottomNavigationBarItem(
            label: 'Contacts',
            icon: Icon(Icons.person),
          ),
          BottomNavigationBarItem(
            label: 'Others',
            icon: Icon(Icons.menu),
          ),
        ],
      ),
    );
  }
}
