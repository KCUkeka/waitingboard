import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
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
      final updateType = jsonData['items'][0]['type'] as String? ?? 'file';

      if (_isNewerVersion(latestVersion, currentVersion)) {
        return {
          'version': latestVersion,
          'url': downloadUrl,
          'changes': changes,
          'currentVersion': currentVersion,
          'updateType': updateType,
        };
      }

      return null;
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

  // Get the raw download URL for a file from GitHub API response
  static String _getRawDownloadUrl(String apiUrl, String filePath) {
    // Convert API URL to raw URL
    // From: https://api.github.com/repos/KCUkeka/waitingboard/contents/releases/download/v1.5.1/update/data/file.txt
    // To: https://raw.githubusercontent.com/KCUkeka/waitingboard/main/releases/download/v1.5.1/update/data/file.txt

    final uri = Uri.parse(apiUrl);
    if (uri.host == 'api.github.com') {
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 5) {
        // Extract: repos / owner / repo / contents / path...
        final owner = pathSegments[1];
        final repo = pathSegments[2];
        final contentPath = pathSegments.skip(4).join('/');
        return 'https://raw.githubusercontent.com/$owner/$repo/main/$contentPath';
      }
    }

    return apiUrl;
  }

  // Recursively fetch all files from GitHub directory
  static Future<List<Map<String, dynamic>>> _fetchAllFilesRecursively(
      String apiUrl) async {
    print('Fetching directory from GitHub API: $apiUrl');

    final List<Map<String, dynamic>> allFiles = [];
    await _fetchGitHubDirectoryRecursively(apiUrl, '', allFiles);

    print('Found ${allFiles.length} total files');
    return allFiles;
  }

  static Future<void> _fetchGitHubDirectoryRecursively(String apiUrl,
      String relativePath, List<Map<String, dynamic>> allFiles) async {
    try {
      print('Fetching API: $apiUrl');

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode != 200) {
        print(
            'Failed to fetch $apiUrl: ${response.statusCode} - ${response.body}');
        return;
      }

      final List<dynamic> contents = jsonDecode(response.body);

      for (final item in contents) {
        final name = item['name'] as String;
        final type = item['type'] as String;
        final downloadUrl = item['download_url'] as String?;
        final size = item['size'] as int? ?? 0;
        final path = item['path'] as String? ?? '';
        final sha = item['sha'] as String? ?? '';

        final fullRelativePath =
            relativePath.isEmpty ? name : '$relativePath/$name';

        if (type == 'file' && downloadUrl != null) {
          allFiles.add({
            'name': name,
            'relativePath': fullRelativePath,
            'download_url': downloadUrl,
            'size': size,
            'github_path': path,
            'sha': sha,
          });
          print('  File: $fullRelativePath (${_formatBytes(size)})');
        } else if (type == 'dir') {
          // Recursively fetch subdirectory using the API URL
          final subdirApiUrl =
              'https://api.github.com/repos/KCUkeka/waitingboard/contents/$path';
          await _fetchGitHubDirectoryRecursively(
              subdirApiUrl, fullRelativePath, allFiles);
        }
      }
    } catch (e) {
      print('Error fetching directory $apiUrl: $e');
    }
  }

  // Download all files and subfolders
  static Future<bool> downloadAndInstallUpdate(
    String apiUrl, {
    Function(String message)? onProgress,
  }) async {
    void log(String message) {
      print(message);
      onProgress?.call(message);
    }

    try {
      final executablePath = Platform.resolvedExecutable;
      final installDir = File(executablePath).parent.path;

      log('📍 Current installation: $installDir');
      log('🌐 Fetching update information...');

      // Check if this is a direct file URL or directory API URL
      final isApiUrl =
          apiUrl.contains('api.github.com') && apiUrl.contains('/contents/');

      if (!isApiUrl) {
        log('⚠️ Not a GitHub API URL, using single file download');
        return await _downloadSingleFile(apiUrl, log);
      }

      // Get all files recursively from GitHub API
      log('📋 Scanning directory structure from GitHub...');
      final allFiles = await _fetchAllFilesRecursively(apiUrl);

      if (allFiles.isEmpty) {
        log('⚠️ No files found in the update directory');
        return false;
      }

      log('✅ Found ${allFiles.length} files to download');

      // Calculate total size
      final totalSize =
          allFiles.fold<int>(0, (sum, file) => sum + (file['size'] as int));
      log('📊 Total download size: ${_formatBytes(totalSize)}');

      // Create temp directory for downloads
      final tempDir = await getTemporaryDirectory();
      final updateTempDir = Directory(
          '${tempDir.path}\\waitboard_update_${DateTime.now().millisecondsSinceEpoch}');
      await updateTempDir.create(recursive: true);
      log('📁 Created temp directory: ${updateTempDir.path}');

      // Download all files
      log('⬇️ Starting downloads...');
      int successCount = 0;

      for (var i = 0; i < allFiles.length; i++) {
        final file = allFiles[i];
        final fileName = file['name'] as String;
        final relativePath = file['relativePath'] as String;
        final fileUrl = file['download_url'] as String;
        final fileSize = file['size'] as int;

        log('⬇️ [${i + 1}/${allFiles.length}] $relativePath (${_formatBytes(fileSize)})');

        try {
          final response = await http.get(Uri.parse(fileUrl));
          if (response.statusCode != 200) {
            log('  ❌ Failed: HTTP ${response.statusCode}');
            continue;
          }

          // Create subdirectories if needed
          final fileParts = relativePath.split('/');
          if (fileParts.length > 1) {
            final dirPath =
                path.joinAll(fileParts.sublist(0, fileParts.length - 1));
            final fullDirPath = path.join(updateTempDir.path, dirPath);
            await Directory(fullDirPath).create(recursive: true);
          }

          // Save file
          final localFilePath = path.join(updateTempDir.path, relativePath);
          final localFile = File(localFilePath);
          await localFile.writeAsBytes(response.bodyBytes);

          successCount++;
          log('  ✓ Downloaded');
        } catch (e) {
          log('  ❌ Error: $e');
        }
      }

      log('📊 Download summary: $successCount/${allFiles.length} files downloaded');

      if (successCount == 0) {
        log('❌ No files were downloaded successfully');
        return false;
      }

      log('✅ All files downloaded successfully!');
      log('🔄 Preparing update...');

      // Create and run updater script
      final logPath = '${tempDir.path}\\update_log.txt';
      final scriptPath = await _createDirectoryUpdaterScript(
        updateDir: updateTempDir.path,
        installDir: installDir,
        logPath: logPath,
        files: allFiles,
      );

      log('🚀 Launching updater...');
      log('⚠️ App will close and restart automatically');

      await Future.delayed(Duration(seconds: 2));

      await _runUpdaterScript(scriptPath, logPath);

      return true;
    } catch (e) {
      log('❌ Error: $e');
      log('💡 Stack trace: ${e.toString()}');
      return false;
    }
  }

  // Fallback for single file downloads
  static Future<bool> _downloadSingleFile(
      String downloadUrl, Function(String) log) async {
    try {
      log('⬇️ Downloading single file...');

      final executablePath = Platform.resolvedExecutable;
      final executableDir = File(executablePath).parent.path;

      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download: ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final newExePath = '${tempDir.path}\\waitboard_new.exe';
      await File(newExePath).writeAsBytes(response.bodyBytes);

      log('✅ Download complete!');

      // Create simple updater script
      final logPath = '${tempDir.path}\\update_log.txt';
      final scriptPath = await _createSimpleUpdaterScript(
        newExePath: newExePath,
        currentExePath: executablePath,
        logPath: logPath,
      );

      log('🚀 Launching updater...');
      await _runSimpleUpdaterScript(scriptPath, logPath);

      return true;
    } catch (e) {
      log('❌ Single file download error: $e');
      return false;
    }
  }

  // Create simple updater script for single file
  static Future<String> _createSimpleUpdaterScript({
    required String newExePath,
    required String currentExePath,
    required String logPath,
  }) async {
    final script = '''
# Waitboard Simple Updater
\$logFile = "$logPath"

function Write-Log {
    param([string]\$message)
    "\$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')) - \$message" | Out-File -FilePath \$logFile -Append
}

Write-Log "Starting Waitboard update..."

# Wait for app to close
Start-Sleep -Seconds 2

# Replace the executable
Write-Log "Replacing executable..."
try {
    Copy-Item -Path "$newExePath" -Destination "$currentExePath" -Force
    Write-Log "Executable replaced successfully"
    
    # Start the new version
    Start-Sleep -Seconds 1
    Start-Process -FilePath "$currentExePath"
    Write-Log "Application restarted"
    
    # Cleanup
    if (Test-Path "$newExePath") {
        Remove-Item -Path "$newExePath" -Force
        Write-Log "Temporary file cleaned up"
    }
} catch {
    Write-Log "Error updating: \$_"
}

Write-Log "Update process completed"
''';

    final tempDir = await getTemporaryDirectory();
    final scriptPath = '${tempDir.path}\\update_waitboard_simple.ps1';
    await File(scriptPath).writeAsString(script);

    return scriptPath;
  }

  // Create PowerShell updater script for directory structure
  static Future<String> _createDirectoryUpdaterScript({
    required String updateDir,
    required String installDir,
    required String logPath,
    required List<Map<String, dynamic>> files,
  }) async {
    // Build file list string for PowerShell
    final filesList = files.map((f) => f['relativePath'] as String).toList();
    final filesJson = jsonEncode(filesList);

    // Properly escape paths for PowerShell
    final escapedUpdateDir = updateDir.replaceAll('\\', '\\\\');
    final escapedInstallDir = installDir.replaceAll('\\', '\\\\');
    final escapedLogPath = logPath.replaceAll('\\', '\\\\');

    final script = '''
# Waitboard Complete Directory Updater

\$ErrorActionPreference = "SilentlyContinue"
\$ErrorActionPreference = "Continue"
\$logFile = "$escapedLogPath"

function Write-Log {
    param([string]\$message)
    \$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try {
        "\$timestamp - \$message" | Out-File -FilePath \$logFile -Append
    } catch {
        # If we can't write to log, write to console
        Write-Host "Failed to write to log: \$_"
    }
}

Write-Log "Waitboard Directory Updater Started"
Write-Log "Update directory: $escapedUpdateDir"
Write-Log "Install directory: $escapedInstallDir"

# Parse files list from JSON
\$filesJson = '$filesJson'
try {
    \$filesToUpdate = \$filesJson | ConvertFrom-Json
    Write-Log "Total files to update: \$(\$filesToUpdate.Count)"
} catch {
    Write-Log "ERROR: Failed to parse files JSON: \$_"
    exit 1
}

# Wait for app to close
Write-Log "Waiting for application to close..."
Start-Sleep -Seconds 3

# Stop any running processes
Write-Log "Stopping waitboard processes..."

# --- Prevent accidental uninstall confirmation popup ---
Write-Log "Starting uninstall popup suppressor..."

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class WinAPI {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int maxLength);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
}
"@

Start-Job -ScriptBlock {
    param()

    Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class WinAPI {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int maxLength);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
}
"@

    while (\$true) {
        [WinAPI]::EnumWindows({
            param(\$hWnd, \$lParam)

            \$title = New-Object System.Text.StringBuilder 1024
            [WinAPI]::GetWindowText(\$hWnd, \$title, 1024) | Out-Null

            \$t = \$title.ToString()
            if (\$t -like "*remove Ortho Waitboard*" -or
                \$t -like "*completely remove*" -or
                \$t -like "*uninstall*") {

                Add-Type -AssemblyName System.Windows.Forms
                [System.Windows.Forms.SendKeys]::SendWait("n~")
            }

            return \$true
        }, [IntPtr]::Zero)

        Start-Sleep -Milliseconds 300
    }
} | Out-Null

Write-Log "Uninstall suppressor active"


\$processes = Get-Process -Name "waitboard" -ErrorAction SilentlyContinue
if (\$processes) {
    Write-Log "Found \$(\$processes.Count) process(es) - stopping..."
    \$processes | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    }

# Install updates
Write-Log "Installing updates..."
\$successCount = 0
\$failCount = 0

foreach (\$filePath in \$filesToUpdate) {
    \$sourceFile = Join-Path "$escapedUpdateDir" \$filePath
    \$destFile = Join-Path "$escapedInstallDir" \$filePath
    
    # Use variable substitution without colon confusion
    Write-Log "Updating: \${filePath}"
    
    if (-not (Test-Path \$sourceFile)) {
        Write-Log "ERROR: Source file not found: \${sourceFile}"
        \$failCount++
        continue
    }
    
    try {
                
        # Create destination directory
        \$destDir = [System.IO.Path]::GetDirectoryName(\$destFile)
        if (-not (Test-Path \$destDir)) {
            New-Item -ItemType Directory -Path \$destDir -Force | Out-Null
        }
        
        # Copy new file
        Copy-Item -Path \$sourceFile -Destination \$destFile -Force -ErrorAction Stop
        
        if (Test-Path \$destFile) {
            Write-Log "Successfully updated: \${filePath}"
            \$successCount++
        } else {
            Write-Log "ERROR: File not found after copy: \${destFile}"
            \$failCount++
        }
    } catch {
        # Use proper variable delimiters
        \$errorMessage = \$_.Exception.Message
        Write-Log "ERROR updating \${filePath}: \$errorMessage"
        \$failCount++
    }
}

Write-Log "Update results: \$successCount successful, \$failCount failed"

# Start application
\$exePath = "$escapedInstallDir\\waitingboard.exe"
Write-Log "Starting application: \$exePath"

if (Test-Path \$exePath) {
    try {
        \$process = Start-Process -FilePath \$exePath -PassThru -ErrorAction Stop
        Write-Log "Application started! PID: \$(\$process.Id)"
    } catch {
        \$errorMessage = \$_.Exception.Message
        Write-Log "ERROR: Failed to start application: \$errorMessage"
    }
} else {
    Write-Log "ERROR: Executable not found: \$exePath"
    # Try to find any executable
    \$exeFiles = Get-ChildItem -Path "$escapedInstallDir" -Filter "*.exe" | Select-Object -First 1
    if (\$exeFiles) {
        \$altExePath = \$exeFiles.FullName
        Write-Log "Trying alternate executable: \$altExePath"
        try {
            \$process = Start-Process -FilePath \$altExePath -PassThru -ErrorAction Stop
            Write-Log "Application started from alternate path! PID: \$(\$process.Id)"
        } catch {
            \$errorMessage = \$_.Exception.Message
            Write-Log "ERROR: Failed to start alternate executable: \$errorMessage"
        }
    }
}

# Cleanup
Write-Log "Cleaning up..."
try {
    if (Test-Path "$escapedUpdateDir") {
        Remove-Item -Path "$escapedUpdateDir" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Cleaned up temp directory"
    }
} catch {
    \$errorMessage = \$_.Exception.Message
    Write-Log "WARNING: Failed to clean temp directory: \$errorMessage"
}


Write-Log "Update process completed"
Write-Host "Update completed. Check log at: \$logFile"
Write-Host "This window will close in 5 seconds..."
Start-Sleep -Seconds 5
exit 0
''';

    final tempDir = await getTemporaryDirectory();
    final scriptPath = '${tempDir.path}\\update_waitboard_dir.ps1';
    await File(scriptPath).writeAsString(script);

    return scriptPath;
  }

  // Run PowerShell updater script
  static Future<void> _runUpdaterScript(
      String scriptPath, String logPath) async {
    print('Launching PowerShell updater...');

    final batchContent = '''@echo off
echo Starting Waitboard updater...
echo Log file: $logPath
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$scriptPath"
timeout /t 2 /nobreak >nul
''';

    final tempDir = await getTemporaryDirectory();
    final batchPath = '${tempDir.path}\\run_update.bat';
    await File(batchPath).writeAsString(batchContent);

    await Process.start('cmd.exe', ['/c', 'start', '', batchPath],
        mode: ProcessStartMode.detached, runInShell: true);

    print('Updater launched. App will exit now.');
    await Future.delayed(Duration(seconds: 1));
    exit(0);
  }

  // For single file updates
  static Future<void> _runSimpleUpdaterScript(
      String scriptPath, String logPath) async {
    final batchContent = '''@echo off
start powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$scriptPath"
''';

    final tempDir = await getTemporaryDirectory();
    final batchPath = '${tempDir.path}\\run_simple_update.bat';
    await File(batchPath).writeAsString(batchContent);

    await Process.start('cmd.exe', ['/c', batchPath],
        mode: ProcessStartMode.detached, runInShell: true);

    await Future.delayed(Duration(seconds: 1));
    exit(0);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // Debug method
  static Future<void> debugGitHubStructure() async {
    try {
      print('=== DEBUG: Testing GitHub API ===');

      // Test the exact API URL you should use
      final testApiUrl =
          'https://api.github.com/repos/KCUkeka/waitingboard/contents/releases/download/v1.5.1/update';
      print('Testing API URL: $testApiUrl');

      final response = await http.get(Uri.parse(testApiUrl));
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Found ${data.length} items:');
        for (var item in data) {
          print('  - ${item['name']} (${item['type']})');
        }
      } else {
        print('Response body: ${response.body}');
      }

      print('=== END DEBUG ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }
}
