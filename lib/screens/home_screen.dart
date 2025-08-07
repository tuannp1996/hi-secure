import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hi_secure/model/app.dart';
import 'package:hi_secure/service/app_service.dart';
import 'package:hi_secure/service/auth_service.dart';
import 'package:hi_secure/screens/account_list_screen.dart';
import 'package:hi_secure/screens/app_form_screen.dart';
import 'package:hi_secure/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<App> apps = [];
  final sharedStorage = AppStorage();
  final authService = AuthService();
  bool _isAuthenticated = false;
  bool _isLoading = true;
  // Remove _failCount since we're not doing automatic authentication

  Future<void> loadApps() async {
    final _apps = await sharedStorage.getApps();

    setState(() {
      this.apps = _apps.cast<App>();
    });
  }

  @override
  void initState() {
    super.initState();
    // Remove automatic authentication - only authenticate when user clicks button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Just load apps without authentication, but keep _isAuthenticated = false
      if (mounted) {
        setState(() {
          _isAuthenticated = false; // Start with authentication required
          _isLoading = false;
        });
        loadApps();
      }
    });
  }

  @override
  void dispose() {
    // Clean up any pending operations
    super.dispose();
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Thông báo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            SizedBox(height: 16),
            Text(
              'Lưu ý:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Đảm bảo thiết bị có cảm biến vân tay/khuôn mặt'),
            Text('• Đã thiết lập vân tay/khuôn mặt trong cài đặt thiết bị'),
            Text('• Đã bật xác thực sinh trắc học trong ứng dụng'),
            // if (_failCount >= 2) ...[ // This line is removed
            //   SizedBox(height: 8),
            //   Text(
            //     'Sau 3 lần thất bại, ứng dụng sẽ tự động thoát.',
            //     style: TextStyle(color: Colors.red),
            //   ),
            // ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  // Platform-specific biometric test method
  Future<void> _testFingerprintDirect() async {
    try {
      print('Home test - Testing platform-specific biometric...');
      
      // Store context reference before async operations
      final currentContext = context;
      
      final result = await authService.authenticatePlatformBiometric(currentContext);
      
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(result ? 'Biometric authentication successful!' : 'Biometric authentication failed'),
            backgroundColor: result ? Colors.green : Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Smart authentication method with platform-specific biometric
  Future<void> _authenticateSmart() async {
    // Store context reference before async operations
    final currentContext = context;
    bool dialogClosed = false;
    
    try {
      print('Home - Starting platform-specific authentication...');
      
      // Show loading dialog
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Xác thực'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Đang chuẩn bị xác thực...',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Hệ thống sẽ tự động chọn phương thức xác thực phù hợp',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Perform platform-specific authentication
      final result = await authService.authenticatePlatformBiometric(currentContext);
      
      // Close loading dialog safely
      if (mounted && !dialogClosed) {
        try {
          Navigator.of(currentContext).pop();
          dialogClosed = true;
        } catch (e) {
          print('Error closing dialog: $e');
        }
      }
      
      if (mounted) {
        if (result) {
          setState(() {
            _isAuthenticated = true;
          });
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('Xác thực thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('Xác thực thất bại hoặc chưa thiết lập'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && !dialogClosed) {
        try {
          Navigator.of(currentContext).pop();
          dialogClosed = true;
        } catch (e) {
          print('Error closing dialog in catch: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Logout function to reset authentication
  void _logout() {
    setState(() {
      _isAuthenticated = false;
    });
    
    // Store context reference before async operations
    final currentContext = context;
    
    ScaffoldMessenger.of(currentContext).showSnackBar(
      SnackBar(
        content: Text('Đã đăng xuất'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openAccounts(App app) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AccountListScreen(app: app)),
    ).then((_) => loadApps());
  }

  void _addApp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AppFormScreen()),
    ).then((_) => loadApps());
  }

  void _editApp(App app) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AppFormScreen(app: app)),
    ).then((_) => loadApps());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.green,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Hi Secure',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Securing your passwords...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    // Show locked state when not authenticated
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.green,
        appBar: AppBar(
          title: Text('Hi Secure'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen()),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _authenticateSmart,
                icon: Icon(Icons.security),
                label: Text('Xác thực ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade800,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Nhấn nút xác thực để mở khóa ứng dụng',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Show main app when authenticated
    return Scaffold(
      appBar: AppBar(
        title: Text('Apps'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: apps.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apps,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No apps yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first app',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo[100],
                      child: Icon(
                        Icons.apps,
                        color: Colors.green[700],
                      ),
                    ),
                    title: Text(
                      app.name,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(app.url ?? 'No URL configured'),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Colors.green[600]),
                      onPressed: () => _editApp(app),
                      tooltip: 'Edit App',
                    ),
                    onTap: () => _openAccounts(app),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addApp,
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
} 