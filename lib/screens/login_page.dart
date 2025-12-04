import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:waitingboard/screens/admin/admin_home_page.dart';
import 'dart:convert';
import 'dart:io';
import 'package:waitingboard/screens/homepage/clinic_home_page.dart';
import 'package:waitingboard/screens/homepage/front_desk_home_page.dart';
import 'package:waitingboard/services/api_service.dart';
import 'package:waitingboard/services/update_service.dart';
import 'signup_page.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  String? _selectedUsername;
  String? _selectedLocation;
  bool _rememberPassword = false;

  /*
    // Update checker variables
  String _currentVersion = '1.4';
  bool _checkingForUpdates = false;

  List<Map<String, dynamic>> _users = [];
  List<String> _locations = [];

  Future<void> _initializePackageInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
      });
    } catch (e) {
      debugPrint('Failed to get package info: $e');
      */

  // Manual refresh method
Future<void> _refreshData() async {
  // Store current values temporarily
  final tempLocation = _selectedLocation;
  final tempUsername = _selectedUsername;
  final tempPassword = _passwordController.text;
  final tempRemember = _rememberPassword;
  
  setState(() {
    _selectedUsername = null;
    _selectedLocation = null;
    _filteredUsernames = [];
    _filteredUsers = [];
    _passwordController.clear();
  });
  
  await _fetchData();
  
  // Restore saved values if "Remember Password" was checked
  if (tempRemember && tempLocation != null) {
    setState(() {
      _selectedLocation = tempLocation;
      _selectedUsername = tempUsername;
      _passwordController.text = tempPassword;
      _rememberPassword = tempRemember;
      
      if (_selectedLocation != null && _users.isNotEmpty) {
        _filterUsernamesByLocation(_selectedLocation!);
      }
    });
  }
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Data refreshed successfully")),
  );
}

  List<Map<String, dynamic>> _users = [];
  List<String> _locations = [];
  List<String> _filteredUsernames = [];
  List<Map<String, dynamic>> _filteredUsers = []; // Store filtered user objects
  
  // This map is to store location-to-username patterns
  final Map<String, List<String>> _locationPatterns = {
    'Riverside': ['Riverside'],
    'IE Riverside': ['Riverside'],
    'Algonquin': ['Algonquin'],
    'Elgin': ['Elgin'],
    'Roxbury': ['Roxbury'],
    'McHenry': ['McHenry'],
    'Perryville': ['Perryville'],
  };

  // Helper function to check if user is Admin/Manager (has admin privileges)
  bool _isAdminOrManagerUser(Map<String, dynamic> user) {
    final role = user['role']?.toString() ?? '';
    final isAdminFlag = user['admin'] == true || user['admin'] == 'true';
    
    // Convert to lowercase for case-insensitive comparison
    final lowerRole = role.toLowerCase().trim();
    
    // Check for Admin (any admin role OR admin flag is true)
    if (isAdminFlag || lowerRole.contains('admin')) {
      return true;
    }
    
    // Check for Manager (any manager role)
    if (lowerRole.contains('manager')) {
      return true;
    }
    
    return false;
  }

  // Helper function to check if user is ViewOnly
  bool _isViewOnlyUser(Map<String, dynamic> user) {
    final role = user['role']?.toString() ?? '';
    final username = user['username']?.toString() ?? '';
    
    // Convert to lowercase for case-insensitive comparison
    final lowerUsername = username.toLowerCase();
   
    
    // HARDCODE specific ViewOnly usernames
    final viewOnlyUsernames = [
      'viewonly', // lowercase
      // Add more ViewOnly usernames here
    ];
    
    if (viewOnlyUsernames.contains(lowerUsername)) {
      return true;
    }
    
    return false;
  }

  // Helper function to check if user should appear in all locations
  bool _isSpecialRoleUser(Map<String, dynamic> user) {
    // Combines both Admin/Manager and ViewOnly users
    return _isAdminOrManagerUser(user) || _isViewOnlyUser(user);
  }





  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadSavedCredentials(); // Load saved credentials
    _fetchData();

// ---------------------------Disabled auto updater----------------------------

  //   WidgetsBinding.instance.addPostFrameCallback((_) async {
  //   // Debug first
  //   await UpdateService.debugGitHubStructure();
  //   _autoCheckForUpdates();
  // });
}

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Load saved credentials from SharedPreferences
Future<void> _loadSavedCredentials() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final savedUsername = prefs.getString('savedUsername');
  final savedPassword = prefs.getString('savedPassword');
  final savedLocation = prefs.getString('savedLocation');
  final rememberPwd = prefs.getBool('rememberPassword') ?? false;

  if (mounted) {
    setState(() {
      _rememberPassword = rememberPwd;
      
      if (savedLocation != null) {
        _selectedLocation = savedLocation;
      }
      
      if (savedUsername != null) {
        _selectedUsername = savedUsername;
      }
      
      if (_rememberPassword && savedPassword != null) {
        _passwordController.text = savedPassword;
      }
    });
    
    // IMPORTANT: Wait for data to be fetched before filtering
    // This ensures users are loaded before we try to filter them
    if (_selectedLocation != null && _users.isNotEmpty) {
      _filterUsernamesByLocation(_selectedLocation!);
    }
  }
}

  // Save credentials to SharedPreferences
  Future<void> _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_rememberPassword) {
      await prefs.setString('savedUsername', _selectedUsername ?? '');
      await prefs.setString('savedPassword', _passwordController.text);
      await prefs.setString('savedLocation', _selectedLocation ?? '');
      await prefs.setBool('rememberPassword', true);
    } else {
      await prefs.remove('savedPassword');
      await prefs.setBool('rememberPassword', false);
      // Still save username and location for convenience
      await prefs.setString('savedUsername', _selectedUsername ?? '');
      await prefs.setString('savedLocation', _selectedLocation ?? '');
    }
  }
  // In your _LoginPageState class, replace _showUpdateDialogWithInstall with this:

  // ⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄ Disabled auto updater ⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄⌄
/*
  void _showUpdateDialogWithInstall(
      String downloadUrl, String version, List changes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version $version is available!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('What\'s new:'),
              const SizedBox(height: 5),
              ...changes
                  .map(
                    (change) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                      child: Text('• ${change['message']}'),
                    ),
                  )
                  .toList(),
              const SizedBox(height: 10),
              const Text(
                'The app will automatically restart after the update is installed.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show progress dialog
              List<String> progressMessages = [];

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: const Text('Installing Update'),
                      content: Container(
                        width: double.maxFinite,
                        constraints: BoxConstraints(maxHeight: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: progressMessages.length,
                                itemBuilder: (context, index) {
                                  final message = progressMessages[index];
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      message,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );

              // Download and install with progress updates
              final success = await UpdateService.downloadAndInstallUpdate(
                downloadUrl,
                onProgress: (message) {
                  if (mounted) {
                    setState(() {
                      // Optional: Show progress in UI
                      print('Update: $message');
                      progressMessages.add(message);
                    });
                  }
                },
              );

              if (!success && mounted) {
                Navigator.pop(context); // Close progress dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Update failed. Please try again.'),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () => _showUpdateDialogWithInstall(
                          downloadUrl, version, changes),
                    ),
                  ),
                );
              }
            },
            child: const Text('Install Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _autoCheckForUpdates() async {
    try {
      await _checkForUpdates(showDialogIfUpToDate: false);
    } catch (e) {
      debugPrint('Auto update check failed: $e');
    }
  }

  Future<void> _manualCheckForUpdates() async {
    await _checkForUpdates(showDialogIfUpToDate: true);
  }

  Future<void> _checkForUpdates({bool showDialogIfUpToDate = true}) async {
    if (_checkingForUpdates) return;

    setState(() {
      _checkingForUpdates = true;
    });

    try {
      final updateInfo = await UpdateService.checkForUpdate();

      if (updateInfo != null) {
        // Update available
        _showUpdateDialogWithInstall(
          updateInfo['url'],
          updateInfo['version'],
          updateInfo['changes'],
        );
      } else {
        // No update available
        if (showDialogIfUpToDate && mounted) {
          _showUpToDateDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update check failed: $e")),
        );
      }
      debugPrint("Update check failed: $e");
    } finally {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });
      }
    }
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();
      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length) return true;
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _showUpdateDialog(String downloadUrl, String version, List changes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version $version is available!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text('What\'s new:'),
              const SizedBox(height: 5),
              ...changes.expand((change) {
                // Split the 'message' into sentences based on punctuation (.!?)
                List<String> sentences = change['message'].split(RegExp(
                    r'(?<=[.!?])\s+')); // Split on sentence-ending punctuation

                // Create a bullet point for each sentence
                return sentences.map(
                  (sentence) => Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 4),
                    child: Text('• $sentence'),
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
              const Text(
                'Click "Download Update" to get the latest version.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchDownload(downloadUrl);
            },
            child: const Text('Download Update'),
          ),
        ],
      ),
    );
  }

  void _showUpToDateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Up to Date'),
        content: const Text(
          'You are using the latest version of Waitboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchDownload(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening download page...'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open download: $e')),
        );
      }
    }
  }

  // Add this method to help you check the log
  Future<void> _showUpdateLog() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final logPath = '${tempDir.path}\\update_log.txt';
      final logFile = File(logPath);

      if (await logFile.exists()) {
        final logContent = await logFile.readAsString();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Update Log'),
            content: SingleChildScrollView(
              child: SelectableText(logContent),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No log file found at: $logPath')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading log: $e')),
      );
    }
  }
  */
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^Disabled auto updater^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


  // Filter usernames based on selected location 
  void _filterUsernamesByLocation(String location) {
    final patterns = _locationPatterns[location];
    
    setState(() {
      _filteredUsers = _users
          .where((user) {
            final username = user['username'] as String;
            final isSpecialUser = _isSpecialRoleUser(user);
            
            // ALWAYS include Admin, Manager, and ViewOnly users
            if (isSpecialUser) {
              return true;
            }
            
            // For non-special users, check if they match the location pattern
            if (patterns == null) {
              return false;
            }
            
            // Check if username contains any location pattern
            return patterns.any((pattern) => username.contains(pattern));
          })
          .toList();
      
      // Sort: location-specific users first, then special users at the bottom
      _filteredUsers.sort((a, b) {
        final usernameA = a['username'] as String;
        final usernameB = b['username'] as String;
        final isSpecialA = _isSpecialRoleUser(a);
        final isSpecialB = _isSpecialRoleUser(b);
        
        // If both are special or both are not special, sort alphabetically
        if (isSpecialA == isSpecialB) {
          return usernameA.compareTo(usernameB);
        }
        
        // Special users go to bottom, non-special users go to top
        return isSpecialA ? 1 : -1;
      });
      
      // Extract just the usernames for the dropdown
      _filteredUsernames = _filteredUsers
          .map((user) => user['username'] as String)
          .toList();
      
      // If current selected username is not in filtered list, clear it
      if (_selectedUsername != null && !_filteredUsernames.contains(_selectedUsername)) {
        _selectedUsername = null;
      }
    });
  }

  // Fetch data from API
  // Fetch data from API
Future<void> _fetchData() async {
  try {
    var users = await ApiService.fetchUsers();
    var locations = await ApiService.fetchLocations();
    
    if (mounted) {
      setState(() {
        _users = users.map((user) {
          return {
            'username': user['username']?.toString() ?? '',
            'password': user['password']?.toString() ?? '',
            'role': user['role']?.toString() ?? '',
            'admin': user['admin'],
          };
        }).toList();
        
        _locations = locations
            .map((location) => location.toString())
            .where((name) => name.isNotEmpty)
            .toList();
        
        // Sort locations to put main locations first
        _locations.sort((a, b) {
          final mainLocations = ['Riverside', 'IE Riverside', 'Algonquin', 'Elgin', 'Roxbury', 'McHenry', 'Perryville'];
          final indexA = mainLocations.indexOf(a);
          final indexB = mainLocations.indexOf(b);
          
          if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
          if (indexA != -1) return -1;
          if (indexB != -1) return 1;
          return a.compareTo(b);
        });
        
        // CRITICAL: After loading users, apply saved location filtering
        if (_selectedLocation != null) {
          _filterUsernamesByLocation(_selectedLocation!);
        }
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load data: $e")),
      );
    }
  }
}

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Find user by username
  Map<String, dynamic>? _findUserByUsername(String username) {
    try {
      return _users.firstWhere((user) => user['username'] == username);
    } catch (e) {
      return null;
    }
  }

  Future<void> _requireAdminBeforeCreateAccount() async {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    String? selectedAdminUsername;
    
    // Filter ONLY Admin/Manager users (exclude ViewOnly)
    final adminManagerUsers = _users.where((user) => 
      _isAdminOrManagerUser(user) // Only Admin/Manager, not ViewOnly
    ).toList();
    
    if (adminManagerUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No admin users available for authorization.")),
      );
      return;
    }
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Admin Authorization Required"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedAdminUsername,
                    items: _users
                        .where((user) =>
                            user['admin'] == true || user['admin'] == 'true')
                        .map<DropdownMenuItem<String>>(
                            (user) => DropdownMenuItem<String>(
                                  value: user['username'] as String,
                                  child: Text(user['username'] as String),
                                ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedAdminUsername = value;
                        usernameController.text = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: "Admin Username"),
                  ),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Admin Password"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final user = _findUserByUsername(selectedAdminUsername ?? '');
                    if (user == null ||
                        hashPassword(passwordController.text.trim()) !=
                            user['password']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Invalid admin credentials.")),
                      );
                      return;
                    }
                    final isAdmin =
                        user['admin'] == true || user['admin'] == 'true';
                    if (!isAdmin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Only admins can create accounts.")),
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateAccountPage()),
                    );
                  },
                  child: Text("Continue"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addNewLocation() async {
    final TextEditingController locationNameController =
        TextEditingController();
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Location"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: usernameController.text.isEmpty
                    ? null
                    : usernameController.text,
                items: _users
                    .where((user) =>
                        user['admin'] == true || user['admin'] == 'true')
                    .map((user) {
                  return DropdownMenuItem(
                    value: user['username']?.toString() ?? '',
                    child: Text('${user['username']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    usernameController.text = value!;
                  });
                },
                decoration: InputDecoration(labelText: "Select Username"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: locationNameController,
                decoration: InputDecoration(labelText: "Location Name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final locationName = locationNameController.text.trim();
                final username = usernameController.text.trim();
                final password = passwordController.text.trim();
                if (locationName.isEmpty ||
                    username.isEmpty ||
                    password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("All fields are required.")),
                  );
                  return;
                }
                final user = _findUserByUsername(username);
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid username.")),
                  );
                  return;
                }
                final isAdmin =
                    user['admin'] == true || user['admin'] == 'true';
                if (!isAdmin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Only admins can add locations.")),
                  );
                  return;
                }
                final hashedPassword = user['password'];
                if (hashPassword(password) != hashedPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid password.")),
                  );
                  return;
                }
                try {
                  await ApiService.addLocation(locationName);
                  await _fetchData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Location added successfully.")),
                  );
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to add location: $e")),
                  );
                }
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetPassword() async {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController adminUsernameController =
        TextEditingController();
    final TextEditingController adminPasswordController =
        TextEditingController();
    String? selectedTargetUsername;
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Reset User Password"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedTargetUsername,
                      items: _users.map((user) {
                        return DropdownMenuItem<String>(
                          value: user['username'],
                          child: Text(user['username']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTargetUsername = value;
                        });
                      },
                      decoration: InputDecoration(
                          labelText: "Select Username to Reset"),
                    ),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "New Password"),
                    ),
                    Divider(height: 20),
                    DropdownButtonFormField<String>(
                      value: adminUsernameController.text.isNotEmpty
                          ? adminUsernameController.text
                          : null,
                      items: _users
                          .where((user) =>
                              user['admin'] == true || user['admin'] == 'true')
                          .map((user) {
                        final username = user['username']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: username,
                          child: Text('$username'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        adminUsernameController.text = value!;
                      },
                      decoration:
                          InputDecoration(labelText: "Select Admin Username"),
                    ),
                    TextField(
                      controller: adminPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "Admin Password"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final targetUsername = selectedTargetUsername?.trim();
                    final newPassword = newPasswordController.text.trim();
                    final adminUsername = adminUsernameController.text.trim();
                    final adminPassword = adminPasswordController.text.trim();
                    if ([
                      targetUsername,
                      newPassword,
                      adminUsername,
                      adminPassword
                    ].any((v) => v == null || v.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("All fields are required.")));
                      return;
                    }
                    final adminUser = _users.firstWhere(
                      (user) => user['username'] == adminUsername,
                      orElse: () => {},
                    );
                    if (adminUser.isEmpty ||
                        hashPassword(adminPassword) != adminUser['password']) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Invalid admin credentials.")));
                      return;
                    }
                    final isAdmin = adminUser['admin'] == true ||
                        adminUser['admin'] == 'true';
                    if (!isAdmin) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Only admins can reset passwords.")));
                      return;
                    }
                    try {
                      await ApiService.resetPassword(
                          targetUsername!, hashPassword(newPassword));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Password reset successfully.")));
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Failed to reset password: $e")));
                    }
                  },
                  child: Text("Reset"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _login() async {
    final username = _selectedUsername;
    final enteredPassword = _passwordController.text.trim();
    if (username == null ||
        _selectedLocation == null ||
        enteredPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields.")),
      );
      return;
    }
    try {
      final user = _findUserByUsername(username);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid username.")),
        );
        return;
      }
      final hashedPassword = user['password'];
      if (hashPassword(enteredPassword) != hashedPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid password.")),
        );
        return;
      }
      final loginSuccess = await ApiService.loginUser(
          username, hashPassword(enteredPassword), _selectedLocation!);
      if (!loginSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to update login time and location.")),
        );
        return;
      }

      // Save credentials if remember password is checked
      await _saveCredentials();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('selectedLocation', _selectedLocation!);

      final isAdmin = user['admin'] == true || user['admin'] == 'true';
      if (isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AdminHomePage(selectedLocation: _selectedLocation!),
          ),
        );
        return;
      }
      if (user['role'] == 'Front desk') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FrontHomePage(selectedLocation: _selectedLocation!),
          ),
        );
      } else if (user['role'] == 'Clinic') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ClinicHomePage(selectedLocation: _selectedLocation!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Role not recognized.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }
// ------------------------------------------ Build Method ------------------------------------------------------
  @override
  Widget build(BuildContext context) {
   return Scaffold(
    appBar: AppBar(
      title: Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            Text('Orthoillinois'),
            Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Text('Wait Times Login'),
            ),
          ],
        ),
      ),
      // Add refresh button here
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _refreshData,
          tooltip: 'Refresh Data',
        ),
      ],
    ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'assets/icons/waitboard.png',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20),
            
            // LOCATION FIELD (FIRST)
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              items: _locations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value;
                  _selectedUsername = null; // Clear username when location changes
                  _filterUsernamesByLocation(value!);
                });
              },
              decoration: InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            SizedBox(height: 20),
            
            // USERNAME FIELD (SECOND - FILTERED)
            DropdownButtonFormField<String>(
              value: _selectedUsername,
              items: _filteredUsernames.map((username) {
                // Simple Text widget without role in parentheses
                return DropdownMenuItem(
                  value: username,
                  child: Text(username),
                );
              }).toList(),
              onChanged: _selectedLocation != null && _filteredUsernames.isNotEmpty
                  ? (value) {
                      setState(() {
                        _selectedUsername = value;
                      });
                    }
                  : null,
              decoration: InputDecoration(
                labelText: _selectedLocation == null 
                    ? 'Select location first'
                    : 'Username',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            
            // Show message if no usernames available for selected location
            if (_selectedLocation != null && _filteredUsernames.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'No users found for $_selectedLocation',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            SizedBox(height: 20),
            
            // PASSWORD FIELD
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
              ),
              onSubmitted: (_) => _login(),
            ),
            Row(
              children: [
                Checkbox(
                  value: _rememberPassword,
                  onChanged: (value) {
                    setState(() {
                      _rememberPassword = value ?? false;
                    });
                  },
                ),
                Text('Remember Password'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextButton(
                onPressed: _resetPassword,
                child: Text('Reset Password'),
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: _requireAdminBeforeCreateAccount,
              child: Text('Create Account'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addNewLocation,
              child: Text('New Location'),
            ),
          ],
        ),
      ),
    );
  }
}