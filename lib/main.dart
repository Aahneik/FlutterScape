import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const FlutterScape());
}

// Theme Management for Color Schemes
class ThemeManager extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  String _currentTheme = 'blue';

  String get currentTheme => _currentTheme;

  final Map<String, Map<String, Color>> _colorSchemes = {
    'blue': {
      'primary': const Color(0xFF667eea),
      'secondary': const Color(0xFF764ba2),
      'accent': Colors.blue,
    },
    'purple': {
      'primary': const Color(0xFF8360c3),
      'secondary': const Color(0xFF2ebf91),
      'accent': Colors.purple,
    },
    'pink': {
      'primary': const Color(0xFFf093fb),
      'secondary': const Color(0xFFf5576c),
      'accent': Colors.pink,
    },
    'green': {
      'primary': const Color(0xFF11998e),
      'secondary': const Color(0xFF38ef7d),
      'accent': Colors.green,
    },
    'orange': {
      'primary': const Color(0xFFf12711),
      'secondary': const Color(0xFFf5af19),
      'accent': Colors.orange,
    },
  };

  Map<String, Color> get currentColors => _colorSchemes[_currentTheme]!;

  ThemeManager() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey) ?? 'blue';
      if (_colorSchemes.containsKey(themeName)) {
        _currentTheme = themeName;
        notifyListeners();
      }
    } catch (e) {
      _currentTheme = 'blue';
    }
  }

  Future<void> setTheme(String themeName) async {
    if (_colorSchemes.containsKey(themeName)) {
      _currentTheme = themeName;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_themeKey, themeName);
      } catch (e) {
        // Continue even if saving fails
      }
      notifyListeners();
    }
  }

  List<String> get availableThemes => _colorSchemes.keys.toList();
}

// Simple Provider Implementation
class ChangeNotifierProvider<T extends ChangeNotifier> extends StatefulWidget {
  final T Function(BuildContext) create;
  final Widget child;

  const ChangeNotifierProvider({
    super.key,
    required this.create,
    required this.child,
  });

  @override
  State<ChangeNotifierProvider<T>> createState() => _ChangeNotifierProviderState<T>();
}

class _ChangeNotifierProviderState<T extends ChangeNotifier> extends State<ChangeNotifierProvider<T>> {
  late T _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = widget.create(context);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProvider<T>(
      notifier: _notifier,
      child: widget.child,
    );
  }
}

class _InheritedProvider<T extends ChangeNotifier> extends InheritedNotifier<T> {
  const _InheritedProvider({
    required T notifier,
    required super.child,
  }) : super(notifier: notifier);
}

class Consumer<T extends ChangeNotifier> extends StatelessWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const Consumer({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_InheritedProvider<T>>();
    return builder(context, provider!.notifier!, child);
  }
}

class FlutterScape extends StatelessWidget {
  const FlutterScape({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            title: 'FlutterScape',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
            ),
            home: SplashScreen(themeManager: themeManager),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final ThemeManager themeManager;
  
  const SplashScreen({super.key, required this.themeManager});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.themeManager.currentColors;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors['primary']!,
              colors['secondary']!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                   child: Image.asset(
                    'assets/images/your_logo.png',
                    width: 110,
                    height: 110,
                  ),

                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut).fadeIn(duration: 800.ms),
              const SizedBox(height: 30),
              const Text(
                'FlutterScape',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate(delay: 300.ms).slideY(begin: 0.3, duration: 600.ms).fadeIn(duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// FIXED: Persistent AppData with SharedPreferences
class AppData {
  static int totalSessions = 0;
  static int totalMinutes = 0;
  static int currentStreak = 0;
  static bool notificationsEnabled = true;
  static bool autoStartEnabled = false;
  static int defaultTimerMinutes = 25;
  static List<Note> notes = [];

  // Load data from SharedPreferences
  static Future<void> loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      totalSessions = prefs.getInt('totalSessions') ?? 0;
      totalMinutes = prefs.getInt('totalMinutes') ?? 0;
      currentStreak = prefs.getInt('currentStreak') ?? 0;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      autoStartEnabled = prefs.getBool('autoStartEnabled') ?? false;
      defaultTimerMinutes = prefs.getInt('defaultTimerMinutes') ?? 25;

      final notesJson = prefs.getStringList('notes') ?? [];
      notes = notesJson
          .map((json) => Note.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      // Keep default values if loading fails
    }
  }

  // Save data to SharedPreferences
  static Future<void> saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('totalSessions', totalSessions);
      await prefs.setInt('totalMinutes', totalMinutes);
      await prefs.setInt('currentStreak', currentStreak);
      await prefs.setBool('notificationsEnabled', notificationsEnabled);
      await prefs.setBool('autoStartEnabled', autoStartEnabled);
      await prefs.setInt('defaultTimerMinutes', defaultTimerMinutes);

      final notesJson = notes
          .map((note) => jsonEncode(note.toJson()))
          .toList();
      await prefs.setStringList('notes', notesJson);
    } catch (e) {
      // Continue even if saving fails
    }
  }

  // Update statistics and save
  static Future<void> updateStats() async {
    totalSessions++;
    totalMinutes += defaultTimerMinutes;
    currentStreak++;
    await saveData();
  }
}

// Add Note class after AppData
class Note {
  String id;
  String text;
  DateTime createdAt;

  Note({required this.id, required this.text, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    text: json['text'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 1500;
  bool _isRunning = false;
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Map<String, double> _soundVolumes = {};
  final Set<String> _playingSounds = {};
  late AnimationController _timerAnimationController;
  late AnimationController _pulseAnimationController;

  @override
  void initState() {
    super.initState();
    _loadAppData();
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    const sounds = ['rain', 'forest', 'ocean', 'fire', 'cafe', 'thunder'];
    for (String sound in sounds) {
      _soundVolumes[sound] = 0.5;
    }
  }

  // FIXED: Load app data and set timer duration
  Future<void> _loadAppData() async {
    await AppData.loadData();
    setState(() {
      _remainingSeconds = AppData.defaultTimerMinutes * 60;
    });
  }

  // FIXED: Update timer when returning from Settings
  void _updateTimerFromSettings() {
    if (!_isRunning) {
      setState(() {
        _remainingSeconds = AppData.defaultTimerMinutes * 60;
      });
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _timerAnimationController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer();
          _showCompletionDialog();
          _updateStats();
        }
      });
    });
  }

  // FIXED: Use AppData.updateStats() method
  void _updateStats() async {
    await AppData.updateStats();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerAnimationController.reverse();
    setState(() {
      _isRunning = false;
      _remainingSeconds = AppData.defaultTimerMinutes * 60;
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timerAnimationController.reverse();
    setState(() {
      _isRunning = false;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('🎉 Session Complete!'),
          content: const Text('Great job! You\'ve completed your session.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Awesome!'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _playSound(String soundId, String assetPath, String title) async {
    try {
      if (_playingSounds.contains(soundId)) {
        await _audioPlayers[soundId]?.stop();
        await _audioPlayers[soundId]?.dispose();
        _audioPlayers.remove(soundId);
        setState(() {
          _playingSounds.remove(soundId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stopped $title')),
        );
      } else {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(_soundVolumes[soundId] ?? 0.5);
        await player.play(AssetSource(assetPath));
        _audioPlayers[soundId] = player;
        setState(() {
          _playingSounds.add(soundId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playing $title')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio file not found - $title')),
      );
    }
  }

  void _updateSoundVolume(String soundId, double volume) {
    setState(() {
      _soundVolumes[soundId] = volume;
    });
    _audioPlayers[soundId]?.setVolume(volume);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    _timerAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final colors = themeManager.currentColors;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors['primary']!,
                  colors['secondary']!,
                ],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AppBar(
                      title: const Text('FlutterScape'),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              drawer: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Drawer(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        DrawerHeader(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                              'assets/images/your_logo.png',
                              width: 65,
                              height: 65,
                            ),

                              SizedBox(height: 12),
                              Text('FlutterScape', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text('Explore your productive side', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                        _buildGlassListTile(Icons.home, 'Home', () => Navigator.pop(context)),
                        _buildGlassListTile(Icons.settings, 'Settings', () async {
                          Navigator.pop(context);
                          // FIXED: Wait for settings and then update timer
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                          _updateTimerFromSettings();
                        }),
                        _buildGlassListTile(Icons.bar_chart, 'Statistics', () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                          );
                        }),
                        _buildGlassListTile(Icons.info, 'About', () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AboutScreen()),
                          );
                        }),
                        _buildGlassListTile(Icons.help, 'Help', () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HelpScreen()),
                          );
                        }),
                        _buildGlassListTile(Icons.note, 'Notes', () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotesScreen()),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FlutterScape',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().slideX(duration: 600.ms).fadeIn(),
                      const SizedBox(height: 30),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Column(
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseAnimationController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _isRunning ? 1.0 + (_pulseAnimationController.value * 0.05) : 1.0,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(60),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                          child: Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white.withOpacity(0.3),
                                                  Colors.white.withOpacity(0.1),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: _isRunning ? Colors.green.withOpacity(0.7) : Colors.white.withOpacity(0.5),
                                                width: 3,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _formatTime(_remainingSeconds),
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _isRunning ? 'Session Active' : 'Ready to Explore',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ).animate().fadeIn(duration: 300.ms),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (!_isRunning) _buildGlassButton('Start Session', _startTimer),
                                    if (_isRunning) _buildGlassButton('Pause', _pauseTimer),
                                    if (_isRunning || _remainingSeconds < AppData.defaultTimerMinutes * 60)
                                      _buildGlassButton('Stop', _stopTimer),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate(delay: 200.ms).slideY(duration: 600.ms).fadeIn(),
                      const SizedBox(height: 30),
                      const Text(
                        '🎵 Sound Library',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ).animate(delay: 400.ms).slideX(duration: 600.ms).fadeIn(),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          children: [
                            _buildSoundItem('rain', 'Gentle Rain', 'Soft rainfall sounds', Icons.grain, Colors.blue, 'sounds/rain.mp3', 0),
                            _buildSoundItem('forest', 'Forest Birds', 'Peaceful forest ambience', Icons.eco, Colors.green, 'sounds/forest.mp3', 1),
                            _buildSoundItem('ocean', 'Ocean Waves', 'Relaxing wave sounds', Icons.waves, Colors.cyan, 'sounds/ocean.mp3', 2),
                            _buildSoundItem('fire', 'Cozy Fire', 'Warm crackling fire', Icons.local_fire_department, Colors.orange, 'sounds/fire.mp3', 3),
                            _buildSoundItem('cafe', 'Coffee Shop', 'Cozy cafe ambience', Icons.coffee, Colors.brown, 'sounds/cafe.mp3', 4),
                            _buildSoundItem('thunder', 'Distant Thunder', 'Rolling thunder sounds', Icons.flash_on, Colors.indigo, 'sounds/thunder.mp3', 5),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGlassButton(String text, VoidCallback onPressed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Text(
                  text,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassListTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: Icon(icon, color: Colors.white),
              title: Text(title, style: const TextStyle(color: Colors.white)),
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoundItem(String soundId, String title, String subtitle, IconData icon, Color color, String assetPath, int index) {
    final isPlaying = _playingSounds.contains(soundId);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(isPlaying ? 0.3 : 0.2),
                  Colors.white.withOpacity(isPlaying ? 0.2 : 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPlaying ? color.withOpacity(0.7) : Colors.white.withOpacity(0.2),
                width: isPlaying ? 2 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _playSound(soundId, assetPath, title),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.3),
                                  color.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.5)),
                            ),
                            child: Icon(icon, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(isPlaying ? 0.4 : 0.2),
                                      Colors.white.withOpacity(isPlaying ? 0.3 : 0.1),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isPlaying) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.volume_down, color: Colors.white, size: 16),
                            Expanded(
                              child: Slider(
                                value: _soundVolumes[soundId] ?? 0.5,
                                onChanged: (value) => _updateSoundVolume(soundId, value),
                                activeColor: Colors.white,
                                inactiveColor: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            const Icon(Icons.volume_up, color: Colors.white, size: 16),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ).animate(delay: Duration(milliseconds: 600 + (index * 100))).slideX(begin: 0.3).fadeIn(duration: 600.ms));
  }
}

// Settings Screen with Theme Color Selector
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final colors = themeManager.currentColors;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors['primary']!,
                  colors['secondary']!,
                ],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AppBar(
                      title: const Text('Settings'),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Color Scheme Settings
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Color Scheme',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Choose your preferred color scheme:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: themeManager.availableThemes.map((themeName) {
                                    final themeColors = themeManager._colorSchemes[themeName]!;
                                    final isSelected = themeManager.currentTheme == themeName;
                                    return GestureDetector(
                                      onTap: () => themeManager.setTheme(themeName),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              themeColors['primary']!,
                                              themeColors['secondary']!,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: isSelected 
                                            ? Border.all(color: Colors.white, width: 3)
                                            : Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                        ),
                                        child: isSelected 
                                          ? const Icon(Icons.check, color: Colors.white, size: 24)
                                          : null,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _getThemeDisplayName(themeManager.currentTheme),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Timer Settings
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Timer Settings',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Default Timer Duration',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: DropdownButton<int>(
                                        value: AppData.defaultTimerMinutes,
                                        dropdownColor: colors['primary']!.withOpacity(0.9),
                                        style: const TextStyle(color: Colors.white),
                                        underline: Container(),
                                        items: const [
                                          DropdownMenuItem(value: 5, child: Text('5 min', style: TextStyle(color: Colors.white))),
                                          DropdownMenuItem(value: 15, child: Text('15 min', style: TextStyle(color: Colors.white))),
                                          DropdownMenuItem(value: 25, child: Text('25 min', style: TextStyle(color: Colors.white))),
                                          DropdownMenuItem(value: 45, child: Text('45 min', style: TextStyle(color: Colors.white))),
                                        ],
                                        onChanged: (value) async {
                                          setState(() {
                                            AppData.defaultTimerMinutes = value!;
                                          });
                                          // FIXED: Save settings immediately
                                          await AppData.saveData();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Auto-Start Sessions',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            'Automatically start timer when opening app',
                                            style: TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: AppData.autoStartEnabled,
                                      onChanged: (value) async {
                                        setState(() {
                                          AppData.autoStartEnabled = value;
                                        });
                                        // FIXED: Save settings immediately
                                        await AppData.saveData();
                                      },
                                      activeColor: Colors.white,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Notifications',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                          ),
                                          Text(
                                            'Get notified when session completes',
                                            style: TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: AppData.notificationsEnabled,
                                      onChanged: (value) async {
                                        setState(() {
                                          AppData.notificationsEnabled = value;
                                        });
                                        // FIXED: Save settings immediately
                                        await AppData.saveData();
                                      },
                                      activeColor: Colors.white,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getThemeDisplayName(String themeName) {
    switch (themeName) {
      case 'blue':
        return 'Ocean Blue';
      case 'purple':
        return 'Purple Mint';
      case 'pink':
        return 'Sunset Pink';
      case 'green':
        return 'Forest Green';
      case 'orange':
        return 'Fire Orange';
      default:
        return themeName;
    }
  }
}

// Statistics Screen - FIXED: Now shows real data
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final colors = themeManager.currentColors;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors['primary']!,
                  colors['secondary']!,
                ],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AppBar(
                      title: const Text('Statistics'),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Your Statistics',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 30),
                            // FIXED: Load and display actual statistics
                            FutureBuilder(
                              future: AppData.loadData(),
                              builder: (context, snapshot) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatCard('Sessions', AppData.totalSessions.toString(), Icons.play_arrow),
                                    _buildStatCard('Minutes', AppData.totalMinutes.toString(), Icons.timer),
                                    _buildStatCard('Streak', '${AppData.currentStreak} days', Icons.local_fire_department),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// About Screen
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final colors = themeManager.currentColors;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors['primary']!,
                  colors['secondary']!,
                ],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AppBar(
                      title: const Text('About'),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.landscape,
                              size: 80,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'FlutterScape',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'FlutterScape is a productivity app designed to help you focus and maintain concentration through timed sessions and ambient sounds. Create your own custom soundscapes by playing multiple sounds simultaneously.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Help Screen
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final colors = themeManager.currentColors;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors['primary']!,
                  colors['secondary']!,
                ],
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: AppBar(
                      title: const Text('Help'),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    children: [
                      _buildHelpSection(
                        'Getting Started',
                        [
                          'Tap "Start Session" to begin a focus timer',
                          'Choose from ambient sounds to help you concentrate',
                          'Play multiple sounds simultaneously for custom soundscapes',
                          'Pause or stop your session anytime',
                        ],
                        Icons.play_arrow,
                        colors,
                      ),
                      const SizedBox(height: 16),
                      _buildHelpSection(
                        'Multiple Sound Support',
                        [
                          'Play multiple ambient sounds at the same time',
                          'Each sound has its own volume control',
                          'Create custom soundscapes by mixing different sounds',
                          'Tap any sound to start/stop it independently',
                        ],
                        Icons.library_music,
                        colors,
                      ),
                      const SizedBox(height: 16),
                      _buildHelpSection(
                        'Theme Customization',
                        [
                          'Choose from multiple color schemes in Settings',
                          'Themes include Ocean Blue, Purple Mint, and more',
                          'Your theme choice is automatically saved',
                          'Each theme provides a unique visual experience',
                        ],
                        Icons.palette,
                        colors,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpSection(String title, List<String> items, IconData icon, Map<String, Color> colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6, right: 8),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// Notes Screen
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        final colors = themeManager.currentColors;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notes'),
            backgroundColor: colors['primary'],
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddDialog(),
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: AppData.notes.length,
            itemBuilder: (context, index) {
              final note = AppData.notes[index];
              return ListTile(
                title: Text(note.text),
                subtitle: Text(
                  note.createdAt.toString().split('.')[0],
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditDialog(note),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteNote(note),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddDialog() {
    _textController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(hintText: 'Enter your note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                _addNote(_textController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Note note) {
    _textController.text = note.text;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: _textController,
          decoration: const InputDecoration(hintText: 'Edit your note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                _editNote(note, _textController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addNote(String text) {
    setState(() {
      AppData.notes.add(Note(
        id: DateTime.now().toString(),
        text: text,
        createdAt: DateTime.now(),
      ));
    });
    AppData.saveData();
  }

  void _editNote(Note note, String newText) {
    setState(() {
      final index = AppData.notes.indexOf(note);
      AppData.notes[index] = Note(
        id: note.id,
        text: newText,
        createdAt: DateTime.now(),
      );
    });
    AppData.saveData();
  }

  void _deleteNote(Note note) {
    setState(() {
      AppData.notes.remove(note);
    });
    AppData.saveData();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}