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

  Future<void> loadApps() async {
    final _apps = await sharedStorage.getApps();

    setState(() {
      this.apps = _apps.cast<App>();
    });
  }

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final passcodeSet = await authService.isPasscodeSet();
    
    if (!passcodeSet) {
      // First time setup
      final setupSuccess = await authService.showSetupDialog(context);
      if (setupSuccess) {
        setState(() {
          _isAuthenticated = true;
          _isLoading = false;
        });
        loadApps();
      } else {
        // User cancelled setup, show loading screen
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Authenticate existing user
      final authenticated = await authService.authenticate(context);
      setState(() {
        _isAuthenticated = authenticated;
        _isLoading = false;
      });
      if (authenticated) {
        loadApps();
      }
    }
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
        backgroundColor: Colors.indigo,
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

    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.indigo,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Authentication Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Please authenticate to access Hi Secure',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _checkAuthentication(),
                icon: Icon(Icons.security),
                label: Text('Authenticate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Apps'),
        backgroundColor: Colors.indigo,
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
                        color: Colors.indigo[700],
                      ),
                    ),
                    title: Text(
                      app.name,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(app.url ?? 'No URL configured'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.indigo[600]),
                          onPressed: () => _editApp(app),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: () => _openAccounts(app),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addApp,
        child: Icon(Icons.add),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
} 