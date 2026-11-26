import 'package:material_ui/material_ui.dart';

import 'database/db_helper.dart';
import 'models/vedic_models.dart';
import 'screens/home_screen.dart';
import 'screens/player_init_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VedicMathApp());
}

class VedicMathApp extends StatelessWidget {
  const VedicMathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vedic Math Mastery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD97706),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD97706),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AppBootstrap(),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  Player? _activePlayer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final active = await DatabaseHelper.instance.getActivePlayer();
    if (!mounted) return;
    setState(() {
      _activePlayer = active;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_activePlayer == null) {
      return PlayerInitScreen(
        onPlayerCreated: (player) {
          setState(() => _activePlayer = player);
        },
      );
    }

    return HomeScreen(
      initialPlayer: _activePlayer!,
      onAllPlayersDeleted: _initPlayer,
    );
  }
}
