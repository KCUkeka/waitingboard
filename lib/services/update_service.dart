import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  static const String updateJsonUrl = 
      'https://raw.githubusercontent.com/KCUkeka/waitingboard/main/releases/app-archive.json';
  
  // Check if update is available
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      final response = await http.get(Uri.parse(updateJsonUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch update info');
      }
      
      final jsonData = jsonDecode(response.body);
      final latestVersion = jsonData['items'][0]['version'];
      final downloadUrl = jsonData['items'][0]['url'];
      final changes = jsonData['items'][0]['changes'] as List;
      
      if (_isNewerVersion(latestVersion, currentVersion)) {
        return {
          'version': latestVersion,
          'url': downloadUrl,
          'changes': changes,
          'currentVersion': currentVersion,
        };
      }
      
      return null; // No update available
    } catch (e) {
      print('Error checking for update: $e');
      return null;
    }
  }
  
  static bool _isNewerVersion(String latest, String current) {
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
  
  // Download and install update
  static Future<bool> downloadAndInstallUpdate(String downloadUrl) async {
    try {
      // Get the current executable path
      final executablePath = Platform.resolvedExecutable;
      final executableDir = File(executablePath).parent.path;
      
      // Download the new executable to a temporary location
      print('Downloading update from: $downloadUrl');
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download update');
      }
      
      // Save the new executable temporarily
      final tempDir = await getTemporaryDirectory();
      final newExePath = '${tempDir.path}\\waitboard_new.exe';
      final newExeFile = File(newExePath);
      await newExeFile.writeAsBytes(response.bodyBytes);
      
      print('Downloaded to: $newExePath');
      
      // Create and save the PowerShell updater script
      final scriptPath = await _createUpdaterScript(
        newExePath: newExePath,
        currentExePath: executablePath,
      );
      
      // Run the PowerShell script and exit the app
      await _runUpdaterScript(scriptPath);
      
      return true;
    } catch (e) {
      print('Error downloading/installing update: $e');
      return false;
    }
  }
  
  // Create the PowerShell updater script
  static Future<String> _createUpdaterScript({
    required String newExePath,
    required String currentExePath,
  }) async {
    final processName = 'waitboard'; // Your app's process name without .exe
    
    final script = '''
# Auto-Updater Script for Waitboard
\$ErrorActionPreference = "Stop"

Write-Host "================================================"
Write-Host "Waitboard Auto-Updater"
Write-Host "================================================"

# Define paths
\$newExePath = "$newExePath"
\$currentExePath = "$currentExePath"
\$processName = "$processName"

# 1. Wait a moment for the app to fully close
Write-Host "Waiting for application to close..."
Start-Sleep -Seconds 3

# 2. Ensure the process is stopped
Write-Host "Ensuring process '\$processName' is stopped..."
Get-Process -Name \$processName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 3. Backup the old executable (optional but recommended)
\$backupPath = "\$currentExePath.backup"
if (Test-Path \$currentExePath) {
    Write-Host "Creating backup of current version..."
    Copy-Item -Path \$currentExePath -Destination \$backupPath -Force
}

# 4. Replace the old executable with the new one
Write-Host "Installing update..."
try {
    Copy-Item -Path \$newExePath -Destination \$currentExePath -Force
    Write-Host "Update installed successfully!"
    
    # Clean up the temporary file
    Remove-Item -Path \$newExePath -Force -ErrorAction SilentlyContinue
    
    # 5. Start the updated application
    Write-Host "Starting updated application..."
    Start-Sleep -Seconds 1
    Start-Process -FilePath \$currentExePath
    
    Write-Host "Update complete! Application restarted."
}
catch {
    Write-Error "Failed to install update: \$_"
    
    # Restore backup if update failed
    if (Test-Path \$backupPath) {
        Write-Host "Restoring backup..."
        Copy-Item -Path \$backupPath -Destination \$currentExePath -Force
        Start-Process -FilePath \$currentExePath
    }
    exit 1
}

# 6. Clean up backup after successful update (after a delay)
Start-Sleep -Seconds 5
Remove-Item -Path \$backupPath -Force -ErrorAction SilentlyContinue

Write-Host "Script finished."
exit 0
''';
    
    final tempDir = await getTemporaryDirectory();
    final scriptPath = '${tempDir.path}\\update_waitboard.ps1';
    final scriptFile = File(scriptPath);
    await scriptFile.writeAsString(script);
    
    return scriptPath;
  }
  
  // Run the PowerShell updater script
  static Future<void> _runUpdaterScript(String scriptPath) async {
    // Run PowerShell script with execution policy bypass
    await Process.start(
      'powershell.exe',
      [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-WindowStyle',
        'Hidden',
        '-File',
        scriptPath,
      ],
      mode: ProcessStartMode.detached,
    );
    
    // Give the script a moment to start
    await Future.delayed(Duration(milliseconds: 500));
    
    // Exit the current application
    exit(0);
  }
}
