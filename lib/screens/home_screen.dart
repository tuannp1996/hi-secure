import 'package:flutter/material.dart';
import 'package:hi_secure/l10n/app_localizations.dart';
import 'package:hi_secure/model/app.dart';
import 'package:hi_secure/service/app_service.dart';
import 'package:hi_secure/service/auth_service.dart';
import 'package:hi_secure/screens/account_list_screen.dart';
import 'package:hi_secure/screens/app_form_screen.dart';
import 'package:hi_secure/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChanged;
  
  const HomeScreen({Key? key, this.onLocaleChanged}) : super(key: key);

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
    try {
      // Initialize default apps if this is the first launch
      await sharedStorage.initializeDefaultApps();
      
      final _apps = await sharedStorage.getApps();

      if (mounted) {
        setState(() {
          this.apps = _apps.cast<App>();
        });
      }
    } catch (e) {
      print('Error loading apps: $e');
      if (mounted) {
        setState(() {
          this.apps = [];
        });
      }
    }
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

  // Smart authentication method with platform-specific biometric
  Future<void> _authenticateSmart() async {
    // Store context reference before async operations
    final currentContext = context;
    bool dialogClosed = false;
    final l10n = AppLocalizations.of(context)!;
    
    try {
      // Show loading dialog
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: Colors.green),
              SizedBox(width: 8),
              Text(l10n.authentication),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                l10n.preparingAuthentication,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                l10n.systemWillChoose,
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // Perform platform-specific authentication
      final result = await authService.authenticatePlatformBiometric(currentContext) ?? false;
      
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
              content: Text(l10n.authenticationSuccess),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(l10n.authenticationFailed),
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
            content: Text('${l10n.error}: $e'),
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
    final l10n = AppLocalizations.of(context)!;
    
    ScaffoldMessenger.of(currentContext).showSnackBar(
      SnackBar(
        content: Text(l10n.loggedOut),
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
    final l10n = AppLocalizations.of(context)!;
    
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
                l10n.appTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                l10n.securingPasswords,
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
          title: Text(l10n.appTitle),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            if (_isAuthenticated)
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingsScreen(onLocaleChanged: widget.onLocaleChanged)),
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
                label: Text(l10n.authenticateNow),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade800,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              SizedBox(height: 16),
              Text(
                l10n.pressToUnlock,
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
        title: Text(l10n.apps),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: l10n.logout,
          ),
          if (_isAuthenticated)
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsScreen(onLocaleChanged: widget.onLocaleChanged)),
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
                    l10n.noAppsYet,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    l10n.tapToAddFirst,
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
                      backgroundColor: Colors.green[100],
                      child: Icon(
                        Icons.apps,
                        color: Colors.green[700],
                      ),
                    ),
                    title: Text(
                      app.name,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(app.url ?? l10n.noUrlConfigured),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Colors.green[600]),
                      onPressed: () => _editApp(app),
                      tooltip: l10n.editApp,
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