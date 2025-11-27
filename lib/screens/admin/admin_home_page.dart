import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:waitingboard/screens/dashboard_page.dart';
import 'package:waitingboard/services/api_service.dart';
import '../login_page.dart';
import '../wait_times_page.dart';
import 'add_provider_page.dart';
import 'edit_providers_list.dart';

class AdminHomePage extends StatefulWidget {
  final String selectedLocation;
  
  AdminHomePage({required this.selectedLocation});
  
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentLocation;
  List<String> _locations = [];
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.selectedLocation;
    _checkLoginStatus();
    _fetchLocations();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Fetch available locations
  Future<void> _fetchLocations() async {
    try {
      var locations = await ApiService.fetchLocations();
      setState(() {
        _locations = locations
            .map((location) => location.toString())
            .where((name) => name.isNotEmpty)
            .toList();
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load locations: $e")),
      );
    }
  }

  // Check login status
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isLoggedIn = prefs.getBool('isLoggedIn');
    if (isLoggedIn == null || !isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  // Switch location
  Future<void> _switchLocation(String newLocation) async {
    setState(() {
      _currentLocation = newLocation;
    });
    
    // Save the new location to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLocation', newLocation);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to $newLocation'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Show location picker dialog
  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Switch Location'),
          content: _isLoadingLocations
              ? Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _locations.map((location) {
                    final isCurrentLocation = location == _currentLocation;
                    return ListTile(
                      title: Text(location),
                      leading: Radio<String>(
                        value: location,
                        groupValue: _currentLocation,
                        onChanged: (value) {
                          if (value != null) {
                            _switchLocation(value);
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      trailing: isCurrentLocation
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        _switchLocation(location);
                        Navigator.of(context).pop();
                      },
                    );
                  }).toList(),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Logout user
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? loginId = prefs.getString('loginId');
    if (loginId != null) {
      try {
        await ApiService.logout(loginId);
      } catch (e) {
        print('Error during logout: $e');
      }
    }
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showLocationPicker,
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Wait Time Dashboard - $_currentLocation'),
                SizedBox(width: 8),
                Icon(Icons.arrow_drop_down, size: 24),
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wait Times'),
            Tab(text: 'Board'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Add Provider') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProviderPage()),
                  );
                } else if (value == 'Providers List') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProvidersList()),
                  );
                } else if (value == 'Switch Location') {
                  _showLocationPicker();
                } else if (value == 'Logout') {
                  _logout();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                    value: 'Add Provider', child: Text('Add Provider')),
                PopupMenuItem(
                    value: 'Providers List', child: Text('Providers List')),
                PopupMenuItem(
                    value: 'Logout',
                    child: Text('Logout')),
              ],
              child: Icon(
                CupertinoIcons.person_crop_circle_fill_badge_plus,
                size: 40,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TabBarView(
          controller: _tabController,
          children: [
            WaitTimesPage(
              tabController: _tabController,
              selectedLocation: _currentLocation,
            ),
            DashboardPage(
              selectedLocation: _currentLocation,
            ),
          ],
        ),
      ),
    );
  }
}