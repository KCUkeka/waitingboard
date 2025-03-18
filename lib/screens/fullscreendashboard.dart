import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waitingboard/model/provider_info.dart' as model;
import 'package:waitingboard/screens/login_page.dart';
import 'package:waitingboard/services/api_service.dart';

class FullScreenDashboardPage extends StatefulWidget {
  final String selectedLocation;

  const FullScreenDashboardPage({Key? key, required this.selectedLocation})
      : super(key: key);

  @override
  _FullScreenDashboardPageState createState() =>
      _FullScreenDashboardPageState();
}

class _FullScreenDashboardPageState extends State<FullScreenDashboardPage> {
  String? _selectedLocation;
  late Future<List<model.ProviderInfo>> _providersFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadLocationAndProviders();
    _providersFuture = _fetchProviders();
    _startTimer();
  }

  Future<void> _loadLocationAndProviders() async {
    final prefs = await SharedPreferences.getInstance();
    final location = prefs.getString('selectedLocation');

    if (location == null) {
      _handleMissingLocation();
      return;
    }

    setState(() {
      _selectedLocation = location;
      _providersFuture = _fetchProviders();
    });

    _startTimer();
  }

  void _handleMissingLocation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No location found, please login again')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    });
  }

  Future<List<model.ProviderInfo>> _fetchProviders() async {
    if (_selectedLocation == null) return [];

    try {
      final providers =
          await ApiService.fetchProvidersByLocation(_selectedLocation!);
      return providers
          .where((p) => p.current_location == _selectedLocation)
          .toList();
    } catch (e) {
      print('Error fetching providers: $e');
      return [];
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _providersFuture = _fetchProviders();
      });
    });
  }

  String formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return "N/A";

    // Logic to show time change
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            _selectedLocation != null
                ? '$_selectedLocation Wait Times'
                : 'Loading Dashboard...',
          ),
        ),
        automaticallyImplyLeading: !kIsWeb,
      ),
      body: _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    if (_selectedLocation == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<model.ProviderInfo>>(
      future: _providersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final providers = snapshot.data ?? [];
        return _buildProviderGrid(providers);
      },
    );
  }

  Widget _buildProviderGrid(List<model.ProviderInfo> providers) {
    if (providers.isEmpty) {
      return const Center(child: Text('No providers available'));
    }

    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount =
              (constraints.maxWidth / 200).floor().clamp(1, 4);

          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            padding: const EdgeInsets.all(16.0),
            itemCount: providers.length,
            itemBuilder: (context, index) =>
                _buildProviderCard(providers[index]),
          );
        },
      ),
    );
  }

  Widget _buildProviderCard(model.ProviderInfo provider) {
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.dashboardName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(provider.specialty, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Wait Time:', style: TextStyle(fontSize: 16)),
            Text(
              '${provider.formattedWaitTime} mins',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Last Changed:', style: TextStyle(fontSize: 16)),
            Text(formatTimestamp(provider.last_changed)),
          ],
        ),
      ),
    );
  }
}
