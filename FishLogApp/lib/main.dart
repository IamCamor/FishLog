import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:share_plus/share_plus.dart'; // TODO: Add to pubspec.yaml for share function
// import 'package:image_picker/image_picker.dart'; // TODO: Add to pubspec.yaml for image picking
// import 'package:google_maps_flutter/google_maps_flutter.dart'; // TODO: Add to pubspec.yaml for real map
// import 'package:firebase_analytics/firebase_analytics.dart'; // TODO: Add for Google Analytics
// import 'package:yandex_appmetrica/yandex_appmetrica.dart'; // TODO: Add for Yandex Metrica (if Flutter plugin available)

// --- Brand Colors from Logo ---
const Color primaryColor = Color(0xFF32B5B0); // Warm turquoise
const Color secondaryColor = Color(0xFF1F3B5C); // Dark blue
const Color backgroundColor = Color(0xFFF7F3EB); // Light beige
const Color textColor = Color(0xFF6E7B8B); // Grey for text and icons

void main() {
  runApp(const FishLogApp());
}

// Global variable to simulate authentication state
// In a real application, this would be managed by a state provider (Provider, Riverpod, BLoC)
bool _isAuthenticated = false; // Default: user is not authenticated

// User Model
class User {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isGuide;
  final String userLevel; // E.g., 'Novice', 'Experienced', 'Top Angler', 'Guide'
  final List<String> favoriteBrands;
  final List<String> favoriteBaits;

  User({
    required this.id,
    required this.name,
    this.avatarUrl = 'https://placehold.co/50x50/cccccc/000000?text=АВ',
    this.isGuide = false,
    this.userLevel = 'Новичок',
    this.favoriteBrands = const [],
    this.favoriteBaits = const [],
  });
}

// Simulation of the current authenticated user
// In a real application, this would be loaded from authentication/storage
User? _currentUser; // Initially null until user authenticates

// TODO: Integration with Google Analytics and Yandex Metrica
// In a real application, analytics SDKs would be used here
void _sendAnalyticsEvent(String eventName, {Map<String, dynamic>? parameters}) {
  print('Analytics Event: $eventName, Parameters: $parameters');
  // Example for Google Analytics (Firebase Analytics):
  // FirebaseAnalytics.instance.logEvent(name: eventName, parameters: parameters);
  // Example for Yandex Metrica (if Flutter plugin available):
  // YandexAppMetrica.reportEvent(eventName, parameters);
}

class FishLogApp extends StatelessWidget {
  const FishLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FishLog',
      theme: ThemeData(
        useMaterial3: true,
        // Define color scheme based on brand colors
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          onPrimary: Colors.white,
          secondary: secondaryColor,
          onSecondary: Colors.white,
          surface: backgroundColor,
          onSurface: textColor,
          background: backgroundColor,
          onBackground: textColor,
          error: Colors.red,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: backgroundColor, // Set background color
        appBarTheme: const AppBarTheme(
          backgroundColor: secondaryColor, // Dark blue for AppBar
          foregroundColor: Colors.white, // White text and icons in AppBar
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: secondaryColor, // Dark blue for bottom navigation
          selectedItemColor: primaryColor, // Turquoise for selected item
          unselectedItemColor: Colors.white.withOpacity(0.7), // Lighter unselected items
          showUnselectedLabels: true,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: textColor),
          bodyMedium: TextStyle(color: textColor.withOpacity(0.8)),
          bodySmall: TextStyle(color: textColor.withOpacity(0.6)),
          titleLarge: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: secondaryColor),
          titleSmall: TextStyle(color: secondaryColor),
          headlineLarge: TextStyle(color: secondaryColor),
          headlineMedium: TextStyle(color: secondaryColor),
          headlineSmall: TextStyle(color: secondaryColor),
        ),
        iconTheme: const IconThemeData(color: textColor), // Default icon color
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: textColor),
          hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: textColor.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: textColor.withOpacity(0.3)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor, // Primary color for buttons
            foregroundColor: Colors.white, // White text on buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor, // Text button color
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white.withOpacity(0.9), // Lighter color for cards
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      // Initial screen for handling user consent
      home: const AuthScreen(),
    );
  }
}

// --- Authentication and Consent Screen ---
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAgreementStatus();
  }

  Future<void> _checkAgreementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final bool agreed = prefs.getBool('agreed_to_terms_and_privacy') ?? false;

    if (agreed) {
      // If user has already agreed, navigate directly to main content
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const FishLogMainContent()),
        );
      });
    } else {
      setState(() {
        _isLoading = false; // Show consent screen
      });
    }
  }

  Future<void> _acceptAgreements() async {
    if (_agreedToTerms && _agreedToPrivacy) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('agreed_to_terms_and_privacy', true);
      _sendAnalyticsEvent('terms_accepted');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const FishLogMainContent()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, примите оба соглашения, чтобы продолжить.')),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            // FishLog Logo (simulation)
            Icon(Icons.낚시, size: 100, color: primaryColor), // Example icon, can be replaced with SVG
            Text(
              'Добро пожаловать в FishLog!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: secondaryColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Для использования приложения, пожалуйста, ознакомьтесь и примите наши условия.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: Text(
                        'Я согласен с Пользовательским соглашением',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      value: _agreedToTerms,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _agreedToTerms = newValue ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: primaryColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Это приложение предназначено для ведения личного дневника рыбалок и взаимодействия с другими рыболовами. Контент, создаваемый пользователями, может быть виден другим участникам сообщества.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Divider(),
                    CheckboxListTile(
                      title: Text(
                        'Я даю согласие на обработку персональных данных',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      value: _agreedToPrivacy,
                      onChanged: (bool? newValue) {
                        setState(() {
                          _agreedToPrivacy = newValue ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: primaryColor,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Ваши данные (уловы, местоположения, профиль) будут храниться на сервере и могут быть использованы для аналитики и улучшения работы приложения. Ваши публичные записи будут видны другим пользователям. Подробнее в нашей Политике конфиденциальности.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _acceptAgreements,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Принять и продолжить'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                _showMessage('Открываю страницу с Политикой конфиденциальности...');
                // TODO: Open WebView or navigate to external link with privacy policy
                _sendAnalyticsEvent('privacy_policy_viewed');
              },
              child: Text(
                'Политика конфиденциальности',
                style: TextStyle(color: primaryColor, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Real authentication
                _isAuthenticated = true; // Simulate login
                _currentUser = User(
                  id: 'user_123',
                  name: 'Рыбак Василий',
                  isGuide: true,
                  userLevel: 'Топ Рыбак',
                  favoriteBrands: ['Shimano', 'Daiwa'],
                  favoriteBaits: ['Воблер', 'Силикон'],
                  avatarUrl: 'https://placehold.co/50x50/${(primaryColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/FFFFFF?text=ВР',
                );
                _sendAnalyticsEvent('user_logged_in_mock');
                _showMessage('Вы вошли как Рыбак Василий');
                // If already agreed, navigate directly
                if (_agreedToTerms && _agreedToPrivacy) {
                   Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const FishLogMainContent()),
                    );
                } else {
                  _showMessage('Примите соглашения перед входом.');
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('Войти (для демонстрации)'),
              style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// --- Main application content (after authentication and consent) ---
class FishLogMainContent extends StatefulWidget {
  const FishLogMainContent({super.key});

  @override
  State<FishLogMainContent> createState() => _FishLogMainContentState();
}

class _FishLogMainContentState extends State<FishLogMainContent> {
  int _selectedIndex = 0; // Index of selected item in bottom navigation

  // List of widgets corresponding to bottom navigation items
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const AddFishingLogScreen(),
      const MapScreen(),
      const RankingScreen(),
      const CompetitionsScreen(),
      const BlogScreen(),
      const ChatScreen(), // New chat screen
      const AdminPanelScreen(), // For demonstration only, access restricted in real app
    ];

    // Send app opened event
    _sendAnalyticsEvent('main_content_loaded', parameters: {'user_id': _currentUser?.id ?? 'guest'});
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Send screen view event
    _sendAnalyticsEvent('screen_view', parameters: {'screen_name': _widgetOptions[index].runtimeType.toString()});
  }

  // Method to toggle authentication state (now handled in AuthScreen, but kept for demonstration)
  void _toggleAuth() {
    setState(() {
      _isAuthenticated = !_isAuthenticated;
      if (!_isAuthenticated) {
        _currentUser = null;
        _sendAnalyticsEvent('user_logged_out');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()), // Return to authentication screen
        );
      } else {
        // This should not be called if user is already on FishLogMainContent
        _showMessage('You are already authenticated.');
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('FishLog', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            if (_isAuthenticated && _currentUser != null) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundImage: NetworkImage(_currentUser!.avatarUrl),
                radius: 16,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_currentUser!.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
                  Row(
                    children: [
                      Text(_currentUser!.userLevel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                      if (_currentUser!.isGuide) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.directions_boat, size: 16, color: Colors.greenAccent), // Guide icon
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
        centerTitle: false, // Disable centering to fit user info
        actions: [
          // Button to simulate login/logout
          IconButton(
            icon: Icon(_isAuthenticated ? Icons.logout : Icons.login),
            onPressed: _toggleAuth,
            tooltip: _isAuthenticated ? 'Log out' : 'Log in',
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add_location_alt),
            label: 'Catch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Rankings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Competitions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: 'Blog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble), // Icon for chat
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
        currentIndex: _selectedIndex,
        // Colors are set in ThemeData.bottomNavigationBarTheme
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensure all items are visible
        unselectedLabelStyle: TextStyle(fontSize: 10), // Reduce font size for fit
        selectedLabelStyle: TextStyle(fontSize: 10),
      ),
    );
  }
}

// --- Data Models ---

// Fishing Log Entry Model (updated)
class FishingLog {
  final String id;
  final String fishType;
  final double weight;
  final double length;
  final String locationName;
  final String notes;
  final String? bait; // Lure
  final String? tackleBrand; // Tackle brand
  final DateTime fishingDate; // Fishing date
  final String? weatherCondition; // Weather conditions
  final double? temperature; // Temperature
  final String userId; // User ID who made the entry
  final String userName; // User name who made the entry

  FishingLog({
    required this.id,
    required this.fishType,
    required this.weight,
    required this.length,
    required this.locationName,
    required this.notes,
    this.bait,
    this.tackleBrand,
    required this.fishingDate,
    this.weatherCondition,
    this.temperature,
    required this.userId,
    required this.userName,
  });

  // Factory constructor to create object from JSON
  factory FishingLog.fromJson(Map<String, dynamic> json) {
    return FishingLog(
      id: json['id'] as String,
      fishType: json['fish_type'] as String,
      weight: (json['weight'] as num).toDouble(),
      length: (json['length'] as num).toDouble(),
      locationName: json['location_name'] as String,
      notes: json['notes'] as String,
      bait: json['bait'] as String?,
      tackleBrand: json['tackle_brand'] as String?,
      fishingDate: DateTime.parse(json['fishing_date'] as String),
      weatherCondition: json['weather_condition'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
    );
  }

  // Method to convert to JSON (for sending to backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id, // ID will be generated on backend in real app
      'fish_type': fishType,
      'weight': weight,
      'length': length,
      'location_name': locationName,
      'notes': notes,
      'bait': bait,
      'tackle_brand': tackleBrand,
      'fishing_date': fishingDate.toIso8601String(),
      'weather_condition': weatherCondition,
      'temperature': temperature,
      'user_id': userId,
      'user_name': userName,
    };
  }
}

// Comment Model for a catch entry
class Comment {
  final String id;
  final String logId; // ID of the entry to which the comment belongs
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.logId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });
}

// Fishing Location Model (for map and ranking)
class FishingLocation {
  final String id;
  final String name;
  final String type; // 'general', 'shop', 'resort', 'pier', 'farm'
  final double latitude;
  final double longitude;
  final double rating; // Average rating
  final bool isPrivate; // Private location (visible only to friends/club)
  final String description;
  // Additional fields for resorts and shops
  final String? phoneNumber;
  final String? websiteUrl;
  final String? telegramLink;
  final List<String>? photos; // Photo URLs

  FishingLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.rating,
    this.isPrivate = false,
    this.description = '',
    this.phoneNumber,
    this.websiteUrl,
    this.telegramLink,
    this.photos,
  });
}

// Angler Ranking Model
class AnglerRanking {
  final String userId;
  final String userName;
  final int totalCatches;
  final double totalWeight;
  final int rank;
  final String userLevel; // User level to display
  final bool isGuide; // Guide status
  final String avatarUrl;

  AnglerRanking({
    required this.userId,
    required this.userName,
    required this.totalCatches,
    required this.totalWeight,
    required this.rank,
    this.userLevel = 'Новичок',
    this.isGuide = false,
    this.avatarUrl = 'https://placehold.co/50x50/cccccc/000000?text=АВ',
  });
}

// Competition Model
class Competition {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String locationName;
  final String organizer;
  final String rules; // Competition rules
  final List<String> mandatoryParams; // Required parameters (e.g., min fish weight)
  final String status; // E.g., 'upcoming', 'active', 'completed'
  final String? imageUrl; // Image for the competition

  Competition({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.locationName,
    required this.organizer,
    required this.rules,
    required this.mandatoryParams,
    required this.status,
    this.imageUrl,
  });
}

// Blog Post Model
class BlogPost {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  String status; // 'pending', 'published', 'rejected'
  String? moderationNotes; // Moderator notes

  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.status = 'pending',
    this.moderationNotes,
  });
}

// --- Helper Widget for Banner Ads ---
class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      height: 60, // Standard banner height
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: Text(
        'Banner Ad',
        style: TextStyle(color: Colors.grey[700], fontSize: 16),
      ),
    );
  }
}

// --- Application Screens ---

class AddFishingLogScreen extends StatefulWidget {
  const AddFishingLogScreen({super.key});

  @override
  State<AddFishingLogScreen> createState() => _AddFishingLogScreenState();
}

class _AddFishingLogScreenState extends State<AddFishingLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fishTypeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _companionsController = TextEditingController();
  final TextEditingController _baitController = TextEditingController();
  final TextEditingController _tackleBrandController = TextEditingController();

  List<String> _imagePaths = [];
  String? _selectedLocationCoords;
  DateTime _selectedDate = DateTime.now();

  String? _currentWeatherCondition;
  double? _currentTemperature;

  // Function to simulate image picking
  void _pickImage() {
    _sendAnalyticsEvent('add_photo_clicked');
    // TODO: Photo upload and storage:
    // Use image_picker package for selecting photos from gallery/camera.
    // Upload photos to the server (e.g., via FormData).
    // Get URLs of uploaded photos for database storage.
    setState(() {
      _imagePaths.add('https://placehold.co/100x100/${(Colors.primaries[1].value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/FFFFFF?text=Фото');
    });
    _showMessage('Photo added (simulation)!');
  }

  // Function to select fishing date
  Future<void> _selectDate(BuildContext context) async {
    _sendAnalyticsEvent('select_date_clicked');
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor, // Header and button color in DatePicker
              onPrimary: Colors.white,
              surface: backgroundColor, // Background color
              onSurface: textColor, // Text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // "OK", "CANCEL" button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _showMessage('Date selected: ${DateFormat('dd.MM.yyyy').format(picked)}');
      // TODO: Get weather data for selected date and location
      // _fetchWeatherForLocation(_selectedLocationCoords, picked);
    }
  }

  // Function to simulate location selection on map
  void _selectLocation() {
    _sendAnalyticsEvent('select_location_clicked');
    // TODO: Map integration for displaying fishing spots:
    // Open a real map (e.g., using google_maps_flutter)
    // Allow user to select a spot on the map, get coordinates and location name.
    setState(() {
      _selectedLocationCoords = '55.75, 37.61'; // Example coordinates
      _locationController.text = 'Moscow River'; // Example location name
    });
    _showMessage('Location selected (simulation)!');
    // TODO: Get weather data for selected location and current date
    // _fetchWeatherForLocation(_selectedLocationCoords, _selectedDate);
  }

  // TODO: Function to get weather (implement with a real API)
  // Future<void> _fetchWeatherForLocation(String? coords, DateTime date) async {
  //   if (coords == null) return;
  //   // Example: http.get('https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=YOUR_API_KEY');
  //   // Process response and update _currentWeatherCondition, _currentTemperature
  //   setState(() {
  //     _currentWeatherCondition = 'Sunny'; // Simulation
  //     _currentTemperature = 25.5; // Simulation
  //   });
  // }


  // Function to submit fishing log data to backend
  Future<void> _submitFishingLog() async {
    _sendAnalyticsEvent('save_log_clicked');
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (!_isAuthenticated || _currentUser == null) {
        _showMessage('You must be authenticated to save a catch.');
        return;
      }

      // Generate a unique ID for simulation, in a real app ID will be from DB
      final String logId = UniqueKey().toString();

      // Data to send to backend
      final FishingLog newLog = FishingLog(
        id: logId,
        fishType: _fishTypeController.text,
        weight: double.tryParse(_weightController.text) ?? 0.0,
        length: double.tryParse(_lengthController.text) ?? 0.0,
        locationName: _locationController.text,
        notes: _notesController.text,
        bait: _baitController.text.isEmpty ? null : _baitController.text,
        tackleBrand: _tackleBrandController.text.isEmpty ? null : _tackleBrandController.text,
        fishingDate: _selectedDate,
        weatherCondition: _currentWeatherCondition, // Pass simulated/real data
        temperature: _currentTemperature, // Pass simulated/real data
        userId: _currentUser!.id,
        userName: _currentUser!.name,
      );


      _showMessage('Sending data...');

      try {
        // Replace with the real address of your PHP backend for adding an entry
        const String apiUrl = 'YOUR_PHP_BACKEND_URL/add_fishing_log.php';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(newLog.toJson()), // Use toJson method
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          if (responseBody['success']) {
            _showMessage('Congratulations on your catch! Data saved successfully.');
            _clearForm();
            // Show options dialog after saving
            _showPostSaveDialog(newLog); // Pass new catch data
            _sendAnalyticsEvent('fishing_log_saved', parameters: {'fish_type': newLog.fishType, 'weight': newLog.weight});
          } else {
            _showMessage('Error saving catch: ${responseBody['message']}');
            _sendAnalyticsEvent('save_log_failed', parameters: {'reason': responseBody['message']});
          }
        } else {
          _showMessage('Server error: ${response.statusCode}');
          _sendAnalyticsEvent('save_log_failed', parameters: {'status_code': response.statusCode});
        }
      } catch (e) {
        _showMessage('An error occurred: $e');
        _sendAnalyticsEvent('save_log_failed', parameters: {'error': e.toString()});
      }
    }
  }

  void _clearForm() {
    _fishTypeController.clear();
    _weightController.clear();
    _lengthController.clear();
    _locationController.clear();
    _notesController.clear();
    _companionsController.clear();
    _baitController.clear();
    _tackleBrandController.clear();
    setState(() {
      _imagePaths = [];
      _selectedLocationCoords = null;
      _selectedDate = DateTime.now();
      _currentWeatherCondition = null;
      _currentTemperature = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Dialog after saving, with share option
  void _showPostSaveDialog(FishingLog savedLog) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Catch Recorded!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Congratulations on your excellent catch!'),
              Text('Type: ${savedLog.fishType}, Weight: ${savedLog.weight} kg'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showMessage('Navigating to ranking (simulation)');
                  _sendAnalyticsEvent('view_ranking_from_dialog');
                  // TODO: Analytics and catch statistics:
                  // Navigate to user's personal statistics screen (graphs, records).
                  // Display ranking among friends/clubs.
                },
                icon: const Icon(Icons.leaderboard),
                label: const Text('View Ranking'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  // TODO: Option to share catch on social networks/messengers.
                  // Need to add share_plus package to pubspec.yaml
                  // Example usage:
                  // await Share.share('I caught a ${savedLog.fishType} weighing ${savedLog.weight} kg at ${savedLog.locationName}! #FishLog');
                  _showMessage('Opening share options...');
                  _sendAnalyticsEvent('share_log_clicked');
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Catch'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _fishTypeController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _companionsController.dispose();
    _baitController.dispose();
    _tackleBrandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Photo section
            Text(
              'Catch Photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100, // Fixed height for demonstration
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imagePaths.length + 1, // +1 for "Add Photo" button
                itemBuilder: (context, index) {
                  if (index == _imagePaths.length) {
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: _pickImage,
                        child: const SizedBox(
                          width: 100,
                          height: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: textColor),
                              Text('Add', style: TextStyle(color: textColor)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    clipBehavior: Clip.antiAlias, // For rounded image corners
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Image.network(
                      _imagePaths[index], // Placeholder image URL
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: Center(child: Text('No Photo', style: TextStyle(color: textColor))),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Catch details section
            Text(
              'Catch Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fishTypeController,
              decoration: const InputDecoration(
                labelText: 'Fish Type',
                hintText: 'E.g., Pike, Perch',
                prefixIcon: Icon(Icons.catching_pokemon), // Fish icon
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter fish type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      hintText: 'E.g., 1.5',
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter weight';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid weight';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _lengthController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Length (cm)',
                      hintText: 'E.g., 50',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter length';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid length';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _baitController,
              decoration: const InputDecoration(
                labelText: 'Lure',
                hintText: 'E.g., Wobbler, Silicone, Worm',
                prefixIcon: Icon(Icons.animation), // Lure icon
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tackleBrandController,
              decoration: const InputDecoration(
                labelText: 'Tackle Brand',
                hintText: 'E.g., Shimano, Daiwa',
                prefixIcon: Icon(Icons.handyman), // Tackle icon
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companionsController,
              decoration: const InputDecoration(
                labelText: 'Who were you fishing with?',
                hintText: 'Names or nicks, separated by commas',
                prefixIcon: Icon(Icons.people),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Fishing Notes',
                hintText: 'Conditions, bait, weather, etc.',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Location, date and weather section
            Text(
              'Time and Place',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              readOnly: true, // Location is selected from map, not typed manually
              decoration: InputDecoration(
                labelText: 'Location on Map',
                hintText: 'Tap to select on map',
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map),
                  onPressed: _selectLocation,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty || _selectedLocationCoords == null) {
                  return 'Please select a location on the map';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Fishing Date',
                    hintText: DateFormat('dd.MM.yyyy').format(_selectedDate),
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  controller: TextEditingController(text: DateFormat('dd.MM.yyyy').format(_selectedDate)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Weather display (after API implementation)
            if (_currentWeatherCondition != null)
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_queue, size: 28, color: textColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weather: ${_currentWeatherCondition ?? 'N/A'}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            'Temperature: ${_currentTemperature != null ? '${_currentTemperature}°C' : 'N/A'}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Save button
            Center(
              child: ElevatedButton.icon(
                onPressed: _submitFishingLog,
                icon: const Icon(Icons.save),
                label: const Text('Save Catch', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Screens ---

// Map Screen
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Simulate fishing locations
  List<FishingLocation> _allFishingLocations = [
    FishingLocation(
      id: 'loc_1',
      name: 'Forest Lake',
      type: 'general',
      latitude: 55.8,
      longitude: 37.5,
      rating: 4.5,
      description: 'Excellent place for spinning, lots of pike.',
      isPrivate: false,
    ),
    FishingLocation(
      id: 'loc_2',
      name: 'Fishing Shop "Klevoe Mesto"',
      type: 'shop',
      latitude: 55.75,
      longitude: 37.6,
      rating: 4.8,
      description: 'Wide selection of tackle and lures.',
      phoneNumber: '+7 (495) 123-45-67',
      websiteUrl: 'https://example.com/klewoe',
      telegramLink: 'https://t.me/klewoe_mesto',
      photos: [
        'https://placehold.co/150x100/${(Colors.lightBlue.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/000000?text=Shop_1',
        'https://placehold.co/150x100/${(Colors.lightBlue.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/000000?text=Shop_2'
      ],
    ),
    FishingLocation(
      id: 'loc_3',
      name: 'Fishing Resort "Rybackiy Khutor"',
      type: 'resort',
      latitude: 55.6,
      longitude: 37.8,
      rating: 4.7,
      description: 'Cozy cabins, boat rental, private pond.',
      isPrivate: false,
      phoneNumber: '+7 (903) 987-65-43',
      websiteUrl: 'https://example.com/hutpr',
      telegramLink: 'https://t.me/rybackiy_hut',
      photos: [
        'https://placehold.co/150x100/${(Colors.redAccent.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/000000?text=Resort_1',
        'https://placehold.co/150x100/${(Colors.redAccent.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/000000?text=Resort_2'
      ],
    ),
    FishingLocation(
      id: 'loc_4',
      name: 'Secret Bay (for members only)',
      type: 'general',
      latitude: 55.9,
      longitude: 37.4,
      rating: 4.9,
      description: 'Private spot, excellent biting for large fish.',
      isPrivate: true, // Private location
    ),
    FishingLocation(
      id: 'loc_5',
      name: 'Fishing Farm "At Grandpa\'s"',
      type: 'farm', // New type
      latitude: 55.7,
      longitude: 37.7,
      rating: 4.2,
      description: 'Paid fishing, carp and sturgeon. Gazebos available.',
      isPrivate: false,
      phoneNumber: '+7 (916) 111-22-33',
      websiteUrl: 'https://example.com/ded-farm',
      telegramLink: 'https://t.me/ded_farm',
      photos: [
        'https://placehold.co/150x100/${(Colors.green.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/000000?text=Farm_1',
        'https://placehold.co/150x100/${(Colors.green.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/000000?text=Farm_2'
      ],
    ),
    FishingLocation(
      id: 'loc_6',
      name: 'Pier "Voskhod"',
      type: 'pier',
      latitude: 55.78,
      longitude: 37.55,
      rating: 4.0,
      description: 'Convenient pier for float fishing.',
      isPrivate: false,
    ),
    FishingLocation(
      id: 'loc_7',
      name: 'Fishing Dock "Zarya"',
      type: 'general',
      latitude: 55.85,
      longitude: 37.65,
      rating: 3.5,
      description: 'Public access, sometimes crowded.',
      isPrivate: false,
    ),
  ];

  String _filterType = 'all'; // 'all', 'shop', 'resort', 'general', 'private', 'pier', 'farm'

  List<FishingLocation> get _filteredLocations {
    return _allFishingLocations.where((location) {
      bool matchesFilter = true;

      if (_filterType == 'private') {
        matchesFilter = location.isPrivate;
      } else if (_filterType != 'all') {
        matchesFilter = location.type == _filterType;
      }

      // If user is not authenticated, hide private locations
      if (!_isAuthenticated && location.isPrivate) {
        return false;
      }

      return matchesFilter;
    }).toList();
  }

  // Helper function to get location type in Russian
  String _getLocationTypeText(String type) {
    switch (type) {
      case 'general':
        return 'Waterbody/Place';
      case 'shop':
        return 'Shop';
      case 'resort':
        return 'Resort';
      case 'pier':
        return 'Pier';
      case 'farm':
        return 'Fish Farm';
      default:
        return 'Unknown';
    }
  }

  // Helper function to get location type color
  Color _getLocationTypeColor(String type) {
    switch (type) {
      case 'general':
        return primaryColor; // Turquoise
      case 'shop':
        return Colors.orange;
      case 'resort':
        return Colors.green;
      case 'pier':
        return Colors.purple;
      case 'farm':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  void _showLocationDetails(BuildContext context, FishingLocation location) {
    _sendAnalyticsEvent('view_location_details', parameters: {'location_id': location.id, 'location_type': location.type});
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                controller: scrollController,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  Text(
                    location.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: secondaryColor),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${location.rating.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          _getLocationTypeText(location.type),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getLocationTypeColor(location.type),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      if (location.isPrivate) ...[
                        const SizedBox(width: 8),
                        const Chip(
                          label: Text('Private', style: TextStyle(color: Colors.white)),
                          backgroundColor: Colors.redAccent,
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Show full description only to authenticated users for private locations
                  if (location.isPrivate && !_isAuthenticated)
                    Text(
                      'Log in to see the full description of this private location.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic, color: Colors.red),
                    )
                  else
                    Text(
                      location.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  const SizedBox(height: 16),
                  // Additional information for shops/resorts
                  if (location.type == 'shop' || location.type == 'resort' || location.type == 'farm') ...[
                    if (location.phoneNumber != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('Phone: ${location.phoneNumber}', style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        ),
                      ),
                    if (location.websiteUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.language, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            // TODO: Open link in browser (url_launcher package)
                            InkWell(
                              onTap: () => _showMessage('Opening website: ${location.websiteUrl}'),
                              child: Text(
                                'Website: ${location.websiteUrl}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (location.telegramLink != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.telegram, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            // TODO: Open link in Telegram (url_launcher package)
                            InkWell(
                              onTap: () => _showMessage('Opening Telegram: ${location.telegramLink}'),
                              child: Text(
                                'Telegram: ${location.telegramLink}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (location.photos != null && location.photos!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Photos:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: secondaryColor),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: location.photos!.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  location.photos![index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[200],
                                    child: const Center(child: Text('No Photo')),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Places'),
                _buildFilterChip('general', 'Waterbodies'),
                _buildFilterChip('shop', 'Shops'),
                _buildFilterChip('resort', 'Resorts'),
                _buildFilterChip('pier', 'Piers'),
                _buildFilterChip('farm', 'Fish Farms'),
                if (_isAuthenticated) _buildFilterChip('private', 'Private'),
              ],
            ),
          ),
        ),
        Expanded(
          // TODO: Integrate with real map (google_maps_flutter)
          // Here will be the GoogleMap widget
          child: Container(
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map, size: 80, color: textColor),
                  const SizedBox(height: 16),
                  Text(
                    'Interactive map will be here',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor),
                  ),
                  Text(
                    'Current filter: ${_filterType == 'all' ? 'All' : _getLocationTypeText(_filterType)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  // List of places under the simulated map
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredLocations.length,
                      itemBuilder: (context, index) {
                        final location = _filteredLocations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: ListTile(
                            leading: Icon(
                              location.type == 'shop' ? Icons.store :
                              location.type == 'resort' || location.type == 'farm' ? Icons.bungalow :
                              location.type == 'pier' ? Icons.sailing :
                              Icons.location_on,
                              color: _getLocationTypeColor(location.type),
                            ),
                            title: Text(location.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: secondaryColor)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_getLocationTypeText(location.type)),
                                if (location.isPrivate)
                                  Text(
                                    'Private place',
                                    style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                                  ),
                                Text('Rating: ${location.rating.toStringAsFixed(1)} ⭐'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.info_outline, color: primaryColor),
                              onPressed: () => _showLocationDetails(context, location),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String type, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: _filterType == type,
        onSelected: (bool selected) {
          setState(() {
            _filterType = selected ? type : 'all';
          });
          _sendAnalyticsEvent('map_filter_changed', parameters: {'filter_type': _filterType});
        },
        selectedColor: primaryColor,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(color: _filterType == type ? Colors.white : textColor),
      ),
    );
  }
}

// Ranking Screen
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Simulate angler ranking data
  final List<AnglerRanking> _anglerRankings = [
    AnglerRanking(id: 'u1', userName: 'Ivan Klev', totalCatches: 150, totalWeight: 500.2, rank: 1, userLevel: 'Top Angler', isGuide: true, avatarUrl: 'https://placehold.co/50x50/${(primaryColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/FFFFFF?text=ИК'),
    AnglerRanking(id: 'u2', userName: 'Anna Shchukina', totalCatches: 120, totalWeight: 450.0, rank: 2, userLevel: 'Experienced', isGuide: false, avatarUrl: 'https://placehold.co/50x50/${(secondaryColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/FFFFFF?text=АЩ'),
    AnglerRanking(id: 'u3', userName: 'Sergey Karas', totalCatches: 90, totalWeight: 300.5, rank: 3, userLevel: 'Guide', isGuide: true, avatarUrl: 'https://placehold.co/50x50/${(backgroundColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/6E7B8B?text=СК'),
    AnglerRanking(id: 'u4', userName: 'Elena Okuneva', totalCatches: 80, totalWeight: 280.1, rank: 4, userLevel: 'Experienced', isGuide: false, avatarUrl: 'https://placehold.co/50x50/${(textColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/FFFFFF?text=ЕО'),
    AnglerRanking(id: 'u5', userName: 'Alexey Poplavok', totalCatches: 75, totalWeight: 250.7, rank: 5, userLevel: 'Novice', isGuide: false),
  ];

  // Simulate location ranking data
  final List<FishingLocation> _locationRankings = [
    FishingLocation(id: 'loc_4', name: 'Secret Bay', type: 'general', latitude: 0, longitude: 0, rating: 4.9, description: ''),
    FishingLocation(id: 'loc_2', name: 'Klevoe Mesto', type: 'shop', latitude: 0, longitude: 0, rating: 4.8, description: ''),
    FishingLocation(id: 'loc_3', name: 'Rybackiy Khutor', type: 'resort', latitude: 0, longitude: 0, rating: 4.7, description: ''),
    FishingLocation(id: 'loc_1', name: 'Forest Lake', type: 'general', latitude: 0, longitude: 0, rating: 4.5, description: ''),
    FishingLocation(id: 'loc_5', name: 'Fishing Farm "At Grandpa\'s"', type: 'farm', latitude: 0, longitude: 0, rating: 4.2, description: ''),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _sendAnalyticsEvent('ranking_tab_changed', parameters: {'tab_index': _tabController.index == 0 ? 'anglers' : 'locations'});
      }
    });
    _sendAnalyticsEvent('ranking_screen_viewed');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BannerAdWidget(), // Banner ad
        TabBar(
          controller: _tabController,
          labelColor: primaryColor, // Selected tab text color
          unselectedLabelColor: textColor, // Unselected tab text color
          indicatorColor: primaryColor, // Indicator color under selected tab
          tabs: const [
            Tab(text: 'Angler Ranking', icon: Icon(Icons.person)),
            Tab(text: 'Location Ranking', icon: Icon(Icons.place)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Angler Ranking
              ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _anglerRankings.length,
                itemBuilder: (context, index) {
                  final angler = _anglerRankings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(angler.avatarUrl),
                        backgroundColor: Colors.grey[200],
                        child: Text(angler.rank.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: secondaryColor)),
                      ),
                      title: Text(
                        angler.userName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: secondaryColor, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Catches: ${angler.totalCatches}, Weight: ${angler.totalWeight} kg'),
                          Row(
                            children: [
                              Text(angler.userLevel, style: Theme.of(context).textTheme.bodySmall),
                              if (angler.isGuide) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.directions_boat, size: 16, color: Colors.green), // Guide icon
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: textColor),
                      onTap: () {
                        _showMessage('Profile of ${angler.userName} (simulation)');
                        _sendAnalyticsEvent('view_angler_profile', parameters: {'user_id': angler.userId});
                        // TODO: Navigate to angler profile page
                      },
                    ),
                  );
                },
              ),
              // Location Ranking
              ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _locationRankings.length,
                itemBuilder: (context, index) {
                  final location = _locationRankings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(location.rating.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      title: Text(
                        location.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: secondaryColor, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Type: ${_getLocationTypeText(location.type)}'),
                      trailing: Icon(Icons.star, color: Colors.amber),
                      onTap: () {
                        _showMessage('Location details ${location.name} (simulation)');
                        _sendAnalyticsEvent('view_location_details_from_ranking', parameters: {'location_id': location.id});
                        // TODO: Navigate to location details page
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper function to get location type in Russian (duplicated for example convenience)
  String _getLocationTypeText(String type) {
    switch (type) {
      case 'general':
        return 'Waterbody/Place';
      case 'shop':
        return 'Shop';
      case 'resort':
        return 'Resort';
      case 'pier':
        return 'Pier';
      case 'farm':
        return 'Fish Farm';
      default:
        return 'Unknown';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// Competitions Screen
class CompetitionsScreen extends StatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen> {
  // Simulate competition list
  final List<Competition> _competitions = [
    Competition(
      id: 'comp_1',
      title: 'Volga Cup 2025',
      description: 'Annual predator fishing competition using spinning tackle. Great prizes!',
      date: DateTime(2025, 7, 15),
      locationName: 'Volgograd Reservoir',
      organizer: 'Volga Predator Club',
      rules: 'Boat fishing. Artificial lures only. Minimum pike weight 1.5 kg.',
      mandatoryParams: ['Min fish weight: 1.5 kg', 'Spinning only'],
      status: 'upcoming',
      imageUrl: 'https://placehold.co/300x200/${(Colors.deepOrange.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/FFFFFF?text=Competition_1',
    ),
    Competition(
      id: 'comp_2',
      title: 'Float Fishing Festival',
      description: 'Family holiday and competition for float fishing carp.',
      date: DateTime(2025, 8, 22),
      locationName: 'Zarechny Pond',
      organizer: 'Fishing Union',
      rules: 'Float rod allowed. Shore fishing only. Catch weight count.',
      mandatoryParams: ['Float only', 'Shore fishing'],
      status: 'upcoming',
      imageUrl: 'https://placehold.co/300x200/${(Colors.lightGreen.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/FFFFFF?text=Competition_2',
    ),
    Competition(
      id: 'comp_3',
      title: 'Winter Midge Cup',
      description: 'Ice fishing competition. Teams participate.',
      date: DateTime(2025, 2, 10),
      locationName: 'Deep Lake',
      organizer: 'Winter Fishing Federation',
      rules: 'Midge tackle only. Limit on number of holes. Weight count.',
      mandatoryParams: ['Midge only', 'Teams (2 pers.)'],
      status: 'completed',
      imageUrl: 'https://placehold.co/300x200/${(Colors.blueGrey.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}/FFFFFF?text=Competition_3',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sendAnalyticsEvent('competitions_screen_viewed');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _competitions.length,
      itemBuilder: (context, index) {
        final comp = _competitions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (comp.imageUrl != null)
                Image.network(
                  comp.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: Center(child: Icon(Icons.image_not_supported, size: 50, color: textColor)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comp.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: secondaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comp.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: textColor),
                        const SizedBox(width: 8),
                        Text(
                          'Date: ${DateFormat('dd.MM.yyyy').format(comp.date)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place, size: 18, color: textColor),
                        const SizedBox(width: 8),
                        Text(
                          'Location: ${comp.locationName}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 18, color: textColor),
                        const SizedBox(width: 8),
                        Text(
                          'Organizer: ${comp.organizer}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Rules:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      comp.rules,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (comp.mandatoryParams.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Required parameters:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      ...comp.mandatoryParams.map((param) => Text('- $param', style: Theme.of(context).textTheme.bodyMedium)).toList(),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Chip(
                        label: Text(comp.status == 'upcoming' ? 'Upcoming' : comp.status == 'active' ? 'Active' : 'Completed', style: TextStyle(color: Colors.white)),
                        backgroundColor: comp.status == 'upcoming' ? primaryColor : comp.status == 'active' ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Blog Screen
class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  // Simulate blog posts list
  final List<BlogPost> _blogPosts = [
    BlogPost(
      id: 'blog_1',
      title: 'My First Trophy Catfish!',
      content: 'A long-awaited catch, had to work hard! Sharing secrets and photos.',
      authorId: 'user_123',
      authorName: 'Fisherman Vasily',
      createdAt: DateTime(2025, 6, 25, 10, 30),
      status: 'published',
    ),
    BlogPost(
      id: 'blog_2',
      title: 'Review of New Wobblers 2025',
      content: 'Tested the latest novelties on our pond. Sharing impressions and results.',
      authorId: 'user_456',
      authorName: 'TacklePro',
      createdAt: DateTime(2025, 6, 20, 14, 0),
      status: 'published',
    ),
    BlogPost(
      id: 'blog_3',
      title: 'How to Choose a Spot for Summer Fishing',
      content: 'Tips for finding promising spots on a river and lake.',
      authorId: 'user_123',
      authorName: 'Fisherman Vasily',
      createdAt: DateTime(2025, 6, 18, 9, 0),
      status: 'pending', // Pending moderation
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sendAnalyticsEvent('blog_screen_viewed');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BannerAdWidget(), // Banner ad
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _blogPosts.length,
            itemBuilder: (context, index) {
              final post = _blogPosts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: secondaryColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Author: ${post.authorName} | ${DateFormat('dd.MM.yyyy HH:mm').format(post.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.content,
                        style: Theme.of(context).textTheme.bodyLarge,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () {
                            _showMessage('Viewing full post (simulation)');
                            _sendAnalyticsEvent('view_blog_post', parameters: {'post_id': post.id});
                            // TODO: Open screen with full post text and comments
                          },
                          child: Text('Read More', style: TextStyle(color: primaryColor)),
                        ),
                      ),
                      if (post.status != 'published')
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Chip(
                            label: Text(post.status == 'pending' ? 'Pending Moderation' : 'Rejected', style: TextStyle(color: Colors.white)),
                            backgroundColor: post.status == 'pending' ? Colors.orange : Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isAuthenticated) // Only authenticated users can write
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                _sendAnalyticsEvent('create_blog_post_clicked');
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CreateBlogPostScreen()),
                );
              },
              icon: const Icon(Icons.add_comment),
              label: const Text('Write Post'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: primaryColor,
              ),
            ),
          ),
      ],
    );
  }
}

// Screen for creating a new blog post
class CreateBlogPostScreen extends StatefulWidget {
  const CreateBlogPostScreen({super.key});

  @override
  State<CreateBlogPostScreen> createState() => _CreateBlogPostScreenState();
}

class _CreateBlogPostScreenState extends State<CreateBlogPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (!_isAuthenticated || _currentUser == null) {
        _showMessage('You must be authenticated to publish a post.');
        return;
      }

      final BlogPost newPost = BlogPost(
        id: UniqueKey().toString(),
        title: _titleController.text,
        content: _contentController.text,
        authorId: _currentUser!.id,
        authorName: _currentUser!.name,
        createdAt: DateTime.now(),
        status: 'pending', // Post-moderation
      );

      _showMessage('Sending post for moderation...');
      _sendAnalyticsEvent('blog_post_submitted');

      try {
        // TODO: Send to backend
        const String apiUrl = 'YOUR_PHP_BACKEND_URL/add_blog_post.php'; // Example API
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': newPost.title,
            'content': newPost.content,
            'author_id': newPost.authorId,
            'author_name': newPost.authorName,
          }),
        );

        if (response.statusCode == 200 && jsonDecode(response.body)['success']) {
          _showMessage('Post successfully sent for moderation!');
          Navigator.of(context).pop(); // Return to blog screen
        } else {
          _showMessage('Error sending post: ${jsonDecode(response.body)['message'] ?? 'Unknown error'}');
        }
      } catch (e) {
        _showMessage('An error occurred: $e');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write New Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Post Title',
                  hintText: 'Enter title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Post Content',
                  hintText: 'Write your post here...',
                  prefixIcon: Icon(Icons.text_fields),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter post content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _submitPost,
                  icon: const Icon(Icons.send),
                  label: const Text('Send for Moderation', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Chat Screen (simulation)
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Simulate chat list
  final List<Map<String, String>> _chats = [
    {'id': 'chat_1', 'name': 'General Fishing Chat', 'lastMessage': 'Hi everyone, who\'s fishing?', 'isGroup': 'true'},
    {'id': 'chat_2', 'name': 'My Fishing Buddies', 'lastMessage': 'Planning a trip tomorrow?', 'isGroup': 'true'},
    {'id': 'chat_3', 'name': 'Anna Shchukina', 'lastMessage': 'Thanks for the lure tip!', 'isGroup': 'false'},
    {'id': 'chat_4', 'name': 'Ivan Klev', 'lastMessage': 'Where\'s your latest catch?', 'isGroup': 'false'},
  ];

  @override
  void initState() {
    super.initState();
    _sendAnalyticsEvent('chat_screen_viewed');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: textColor),
            SizedBox(height: 16),
            Text('You need to be authenticated to access chats.', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: chat['isGroup'] == 'true' ? primaryColor : secondaryColor,
              child: Icon(chat['isGroup'] == 'true' ? Icons.group : Icons.person, color: Colors.white),
            ),
            title: Text(chat['name']!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: secondaryColor, fontWeight: FontWeight.bold)),
            subtitle: Text(chat['lastMessage']!, style: Theme.of(context).textTheme.bodyMedium),
            trailing: const Icon(Icons.arrow_forward_ios, color: textColor),
            onTap: () {
              _showMessage('Opening chat with ${chat['name']} (simulation)');
              _sendAnalyticsEvent('chat_opened', parameters: {'chat_id': chat['id']});
              // TODO: Navigate to specific chat screen
            },
          ),
        );
      },
    );
  }
}

// Admin Panel Screen
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  // Simulate fishing log entries list
  List<FishingLog> _fishingLogs = [];
  bool _isLoading = false;

  // Simulate stop words (should be stored on backend)
  final List<String> _stopWords = ['badword1', 'badword2', 'плохоеслово1', 'плохоеслово2'];

  @override
  void initState() {
    super.initState();
    _fetchFishingLogs(); // Load simulated data on initialization
    _sendAnalyticsEvent('admin_panel_viewed');
  }

  // Function to simulate fetching fishing log entries from backend
  Future<void> _fetchFishingLogs() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Fetch entries:
    // Implement HTTP request to your PHP API (e.g., /api/fishing_logs) to get all logs.
    // final response = await http.get(Uri.parse('YOUR_PHP_BACKEND_URL/get_fishing_logs.php'));
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonLogs = jsonDecode(response.body);
    //   _fishingLogs = jsonLogs.map((json) => FishingLog.fromJson(json)).toList();
    // } else {
    //   _showMessage('Error loading logs: ${response.statusCode}');
    // }

    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    setState(() {
      // Example simulated data
      _fishingLogs = [
        FishingLog(
          id: 'log_1',
          fishType: 'Pike',
          weight: 2.5,
          length: 65.0,
          locationName: 'Lake Svetloe',
          notes: 'Caught on a wobbler, great weather.',
          fishingDate: DateTime(2025, 6, 20),
          userId: 'user_123',
          userName: 'Fisherman Vasily',
        ),
        FishingLog(
          id: 'log_2',
          fishType: 'Perch',
          weight: 0.3,
          length: 20.0,
          locationName: 'Fast River',
          notes: 'Bit well on a small spinner.',
          fishingDate: DateTime(2025, 6, 18),
          userId: 'user_456',
          userName: 'Anna Shchukina',
        ),
        FishingLog(
          id: 'log_3',
          fishType: 'Crucian Carp',
          weight: 0.8,
          length: 30.0,
          locationName: 'Zarechny Pond',
          notes: 'On a worm, good after rain. This contains a badword1.',
          fishingDate: DateTime(2025, 6, 15),
          userId: 'user_789',
          userName: 'Sergey Karas',
        ),
      ];
      _isLoading = false;
    });
    _showMessage('Log list loaded (simulation).');
  }

  // Function to simulate deleting a fishing log entry
  void _deleteFishingLog(String logId) async {
    _showMessage('Attempting to delete entry $logId...');
    _sendAnalyticsEvent('admin_delete_log', parameters: {'log_id': logId});

    // TODO: Delete entries:
    // Implement HTTP request to your PHP API (e.g., /api/fishing_logs/{id}) for deleting an entry.
    // Send the ID of the entry to be deleted.
    // final response = await http.post(
    //   Uri.parse('YOUR_PHP_BACKEND_URL/delete_fishing_log.php'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'id': logId}),
    // );
    // if (response.statusCode == 200 && jsonDecode(response.body)['success']) {
    //   _showMessage('Entry $logId deleted successfully!');
    //   _fetchFishingLogs(); // Refresh list after deletion
    // } else {
    //   _showMessage('Error deleting entry $logId.');
    // }

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    setState(() {
      _fishingLogs.removeWhere((log) => log.id == logId);
    });
    _showMessage('Entry $logId deleted (simulation)!');
  }

  // Simulate comments for a catch
  List<Comment> _getCommentsForLog(String logId) {
    // In a real application, this would be a backend request
    if (logId == 'log_1') {
      return [
        Comment(id: 'c1', logId: 'log_1', userId: 'user_456', userName: 'Anna Shchukina', text: 'Congratulations on the trophy!', createdAt: DateTime(2025, 6, 20, 11, 0)),
        Comment(id: 'c2', logId: 'log_1', userId: 'user_789', userName: 'Sergey Karas', text: 'Well done, Vasily!', createdAt: DateTime(2025, 6, 20, 12, 0)),
      ];
    } else if (logId == 'log_3') {
      return [
        Comment(id: 'c3', logId: 'log_3', userId: 'user_123', userName: 'Fisherman Vasily', text: 'Interesting notes!', createdAt: DateTime(2025, 6, 16, 9, 0)),
      ];
    }
    return [];
  }

  // Function to simulate adding a comment
  Future<void> _addComment(String logId, String commentText) async {
    if (_currentUser == null) {
      _showMessage('You must be authenticated to add a comment.');
      return;
    }

    // TODO: Send comment to backend
    _showMessage('Adding comment: $commentText to catch $logId...');
    _sendAnalyticsEvent('add_comment_clicked', parameters: {'log_id': logId});

    // Simple stop word moderation simulation
    bool containsStopWord = _stopWords.any((word) => commentText.toLowerCase().contains(word));
    if (containsStopWord) {
      _showMessage('Comment contains forbidden words and has been sent for moderation.');
      // In a real application, the comment status would be "pending" and await approval
      _sendAnalyticsEvent('comment_moderated', parameters: {'log_id': logId, 'status': 'pending'});
    } else {
      _showMessage('Comment added (simulation)!');
      // In a real application, after successful submission, refresh UI
      _sendAnalyticsEvent('comment_added', parameters: {'log_id': logId});
    }
  }

  void _showCommentsDialog(BuildContext context, FishingLog log) {
    final TextEditingController commentController = TextEditingController();
    List<Comment> comments = _getCommentsForLog(log.id); // Get simulated comments

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Comments for catch "${log.fishType}"', style: TextStyle(color: secondaryColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (comments.isEmpty)
                  Text('No comments yet.', style: Theme.of(context).textTheme.bodyMedium)
                else
                  ...comments.map((comment) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          color: backgroundColor,
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(comment.userName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                Text(comment.text, style: Theme.of(context).textTheme.bodyMedium),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Text(
                                    DateFormat('dd.MM.yy HH:mm').format(comment.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )).toList(),
                const SizedBox(height: 16),
                if (_isAuthenticated) // Only authenticated users can comment
                  TextFormField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'Your comment',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.send, color: primaryColor),
                        onPressed: () {
                          if (commentController.text.isNotEmpty) {
                            _addComment(log.id, commentController.text);
                            commentController.clear();
                            // In a real application, here you would need setState to refresh the comment list
                            // setState(() { comments.add(newComment); });
                          }
                        },
                      ),
                    ),
                    maxLines: null,
                  ),
                if (!_isAuthenticated)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Authenticate to leave comments.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red)),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: textColor),
            SizedBox(height: 16),
            Text('You need to be authenticated to access the admin panel.', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Administrator Tools',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: secondaryColor),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _showMessage('Bulk upload/edit points (TODO)');
                      _sendAnalyticsEvent('admin_bulk_upload');
                    },
                    icon: Icon(Icons.upload_file),
                    label: Text('Bulk Upload Points'),
                    style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showMessage('Block/manage users (TODO)');
                      _sendAnalyticsEvent('admin_manage_users');
                    },
                    icon: Icon(Icons.block),
                    label: Text('Block Users'),
                    style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showMessage('Send push notification to all users (TODO)');
                      _sendAnalyticsEvent('admin_send_push');
                    },
                    icon: Icon(Icons.notifications_active),
                    label: Text('Push Notification'),
                    style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showMessage('Blog moderation (TODO: implement separate screen)');
                      _sendAnalyticsEvent('admin_moderate_blog');
                      // TODO: Implement a separate screen for blog post moderation
                      // Navigator.of(context).push(MaterialPageRoute(builder: (context) => BlogModerationScreen()));
                    },
                    icon: Icon(Icons.rate_review),
                    label: Text('Blog Moderation'),
                    style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Manage Fishing Entries',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: secondaryColor),
              ),
            ],
          ),
        ),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _fishingLogs.isEmpty
                ? const Center(child: Text('No fishing entries.', style: TextStyle(color: textColor)))
                : Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: _fishingLogs.length,
                      itemBuilder: (context, index) {
                        final log = _fishingLogs[index];
                        // Check for stop words in notes
                        bool hasStopWords = _stopWords.any((word) => log.notes.toLowerCase().contains(word));
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      log.fishType,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
                                    ),
                                    Text(
                                      DateFormat('dd.MM.yyyy').format(log.fishingDate),
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Angler: ${log.userName}', style: Theme.of(context).textTheme.bodyMedium),
                                Text('Weight: ${log.weight} kg, Length: ${log.length} cm', style: Theme.of(context).textTheme.bodyMedium),
                                Text('Location: ${log.locationName}', style: Theme.of(context).textTheme.bodyMedium),
                                if (log.bait != null && log.bait!.isNotEmpty)
                                  Text('Lure: ${log.bait}', style: Theme.of(context).textTheme.bodyMedium),
                                if (log.tackleBrand != null && log.tackleBrand!.isNotEmpty)
                                  Text('Tackle: ${log.tackleBrand}', style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 8),
                                Text('Notes: ${log.notes}', style: Theme.of(context).textTheme.bodyMedium),
                                if (hasStopWords)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      'Warning: Entry contains potentially forbidden words!',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showCommentsDialog(context, log),
                                      icon: Icon(Icons.comment, color: primaryColor),
                                      label: Text('Comments', style: TextStyle(color: primaryColor)),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _deleteFishingLog(log.id),
                                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ],
    );
  }
}
