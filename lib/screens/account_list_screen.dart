import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hi_secure/model/app.dart';
import 'package:hi_secure/model/account.dart';
import 'package:hi_secure/screens/account_form_screen.dart';
import 'package:hi_secure/service/auth_service.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

final storage = FlutterSecureStorage();

class AccountListScreen extends StatefulWidget {
  final App app;

  const AccountListScreen({super.key, required this.app});

  @override
  State<AccountListScreen> createState() => _AccountListScreenState();
}

class _AccountListScreenState extends State<AccountListScreen> {
  List<MapEntry<String, Account>> accounts = [];
  final Map<String, bool> _visiblePasswords = {};
  final Map<String, Timer> _passwordTimers = {};
  final authService = AuthService();

  Future<void> loadAccounts() async {
    final all = await storage.readAll();
    final result = <MapEntry<String, Account>>[];

    for (var entry in all.entries) {
      if (entry.key.startsWith('account_${widget.app.name}_')) {
        final jsonMap = jsonDecode(entry.value);
        final acc = Account.fromJson(jsonMap);
        result.add(MapEntry(entry.key, acc));
      }
    }

    setState(() {
      accounts = result;
    });
  }

  Future<void> deleteAccount(String key) async {
    await storage.delete(key: key);
    await loadAccounts();
  }

     @override
   void initState() {
     super.initState();
     loadAccounts();
   }

   @override
   void dispose() {
     // Cancel all timers when widget is disposed
     for (var timer in _passwordTimers.values) {
       timer.cancel();
     }
     _passwordTimers.clear();
     super.dispose();
   }

  void _addAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountFormScreen(appName: widget.app.name),
      ),
    ).then((_) => loadAccounts());
  }

  void _editAccount(MapEntry<String, Account> entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountFormScreen(
          appName: widget.app.name,
          account: entry.value,
          accountKey: entry.key,
        ),
      ),
    ).then((_) => loadAccounts());
  }

    Future<void> _handleRevealPassword(String key) async {
    final biometricEnabled = await authService.isBiometricEnabled();
    final biometricAvailable = await authService.isBiometricAvailable();

    if (biometricEnabled && biometricAvailable) {
      final didAuthenticate = await authService.authenticateWithBiometric();
      
      if (didAuthenticate) {
        setState(() {
          _visiblePasswords[key] = true;
        });
        _startPasswordTimer(key);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Password revealed (30s)'),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Copy',
              textColor: Colors.white,
              onPressed: () => _copyPassword(accounts.firstWhere((entry) => entry.key == key).value.password, key),
            ),
          ),
        );
      }
    } else {
      // Show passcode dialog when biometric is not available
      _showPasscodeDialog(key);
    }
  }

           void _showPasscodeDialog(String key) {
      final passcodeController = TextEditingController();
      String enteredPasscode = '';
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Enter Passcode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter your passcode to view the password',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
                         TextField(
               controller: passcodeController,
               decoration: InputDecoration(
                 labelText: 'Passcode',
                 border: OutlineInputBorder(),
                 prefixIcon: Icon(Icons.security),
                 hintText: 'Enter 6-digit passcode',
               ),
               obscureText: true,
               keyboardType: TextInputType.number,
               maxLength: 6,
               onChanged: (value) {
                 enteredPasscode = value;
               },
             ),
             SizedBox(height: 8),
                         Text(
               'Enter your 6-digit passcode',
               style: TextStyle(
                 fontSize: 12,
                 color: Colors.grey[600],
                 fontStyle: FontStyle.italic,
               ),
             ),
          ],
        ),
        actions: [
                     TextButton(
             onPressed: () {
               Navigator.pop(dialogContext);
             },
             child: Text('Cancel'),
           ),
           ElevatedButton(
             onPressed: () {
               _verifyPasscode(key, enteredPasscode);
             },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: Text('Verify'),
          ),
        ],
      ),
    ),
  );
  }

                   void _verifyPasscode(String key, String enteredPasscode) async {
      try {
        final isValid = await authService.authenticateWithPasscode(enteredPasscode);
        
        if (isValid) {
          // Close the dialog first
          Navigator.pop(context);
          
          if (mounted) {
            setState(() {
              _visiblePasswords[key] = true;
            });
            _startPasswordTimer(key);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Password revealed (30s)'),
                  ],
                ),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'Copy',
                  textColor: Colors.white,
                  onPressed: () => _copyPassword(accounts.firstWhere((entry) => entry.key == key).value.password, key),
                ),
              ),
            );
          }
        } else {
          // Show error in the dialog context
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Incorrect passcode'),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle any errors gracefully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
      }

          void _copyPassword(String password, String key) {
     Clipboard.setData(ClipboardData(text: password));
     
     // Hide password after copying
     setState(() {
       _visiblePasswords[key] = false;
     });
     
     // Cancel timer since password is now hidden
     _passwordTimers[key]?.cancel();
     _passwordTimers.remove(key);
     
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Row(
           children: [
             Icon(Icons.copy, color: Colors.white),
             SizedBox(width: 8),
             Text('Password copied to clipboard'),
           ],
         ),
         backgroundColor: Colors.blue,
         duration: Duration(seconds: 2),
       ),
     );
   }

  void _startPasswordTimer(String key) {
    // Cancel existing timer if any
    _passwordTimers[key]?.cancel();
    
    // Start new timer for 30 seconds
    _passwordTimers[key] = Timer(Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _visiblePasswords[key] = false;
        });
        _passwordTimers.remove(key);
      }
    });
  }

   String _maskUsername(String username) {
     if (username.length <= 2) {
       return username;
     }
     
     final firstChar = username[0];
     final lastChar = username[username.length - 1];
     final middleStars = '*' * (username.length - 2);
     
     return '$firstChar$middleStars$lastChar';
   }

  Future<void> _openAppOrWebsite(App app) async {
    final url = app.url;
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy URL hoặc app để mở')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.app.name} Accounts'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: accounts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No accounts yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first account',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final entry = accounts[index];
                final account = entry.value;
                final isPasswordVisible = _visiblePasswords[entry.key] == true;

                                 return Dismissible(
                   key: Key(entry.key),
                   background: Container(
                     color: Colors.red,
                     alignment: Alignment.centerLeft,
                     padding: EdgeInsets.only(left: 20),
                     child: Icon(
                       Icons.delete,
                       color: Colors.white,
                       size: 30,
                     ),
                   ),
                   secondaryBackground: Container(
                     color: Colors.blue,
                     alignment: Alignment.centerRight,
                     padding: EdgeInsets.only(right: 20),
                     child: Icon(
                       Icons.open_in_browser,
                       color: Colors.white,
                       size: 30,
                     ),
                   ),
                   confirmDismiss: (direction) async {
                     if (direction == DismissDirection.startToEnd) {
                       // Delete action
                       return await _showDeleteDialog(entry.key, account.username);
                     } else {
                       // Open website action
                       await _openAppOrWebsite(widget.app);
                       return false; // Don't dismiss
                     }
                   },
                   onDismissed: (direction) {
                     if (direction == DismissDirection.startToEnd) {
                       deleteAccount(entry.key);
                     }
                   },
                   child: GestureDetector(
                     onLongPress: () => _showOptionsDialog(entry, account),
                     child: Card(
                       margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                       child: ListTile(
                         leading: CircleAvatar(
                           backgroundColor: Colors.indigo[100],
                           child: Icon(
                             Icons.person,
                             color: Colors.indigo[700],
                           ),
                         ),
                         title: Text(
                           isPasswordVisible ? account.username : _maskUsername(account.username),
                           style: TextStyle(fontWeight: FontWeight.w500),
                         ),
                         subtitle: Text(
                           isPasswordVisible ? account.password : '••••••••••',
                           style: TextStyle(
                             fontFamily: 'monospace',
                             fontSize: 12,
                           ),
                         ),
                         trailing: IconButton(
                           icon: Icon(
                             isPasswordVisible
                                 ? Icons.visibility_off
                                 : Icons.visibility,
                             color: Colors.indigo[600],
                           ),
                           onPressed: () => _handleRevealPassword(entry.key),
                         ),
                       ),
                     ),
                   ),
                 );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: Icon(Icons.add),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

     Future<bool> _showDeleteDialog(String key, String username) async {
     return await showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('Delete Account'),
         content: Text('Are you sure you want to delete the account for "$username"?'),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context, false),
             child: Text('Cancel'),
           ),
           TextButton(
             onPressed: () {
               Navigator.pop(context, true);
             },
             child: Text(
               'Delete',
               style: TextStyle(color: Colors.red),
             ),
           ),
         ],
       ),
     ) ?? false;
   }

   void _showOptionsDialog(MapEntry<String, Account> entry, Account account) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: Text('Account Options'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             ListTile(
               leading: Icon(Icons.visibility, color: Colors.indigo),
               title: Text('View Password'),
               onTap: () {
                 Navigator.pop(context);
                 _handleRevealPassword(entry.key);
               },
             ),
             ListTile(
               leading: Icon(Icons.edit, color: Colors.indigo),
               title: Text('Edit Account'),
               onTap: () {
                 Navigator.pop(context);
                 _editAccount(entry);
               },
             ),
             if (_visiblePasswords[entry.key] == true)
               ListTile(
                 leading: Icon(Icons.copy, color: Colors.blue),
                 title: Text('Copy Password'),
                 onTap: () {
                   Navigator.pop(context);
                   _copyPassword(account.password, entry.key);
                 },
               ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: Text('Cancel'),
           ),
         ],
       ),
     );
   }
}