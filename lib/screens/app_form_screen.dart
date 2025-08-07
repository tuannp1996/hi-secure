import 'package:flutter/material.dart';
import 'package:hi_secure/model/app.dart';
import 'package:hi_secure/service/app_service.dart';

class AppFormScreen extends StatefulWidget {
  final App? app; // null for add, non-null for edit

  const AppFormScreen({super.key, this.app});

  @override
  State<AppFormScreen> createState() => _AppFormScreenState();
}

class _AppFormScreenState extends State<AppFormScreen> {
  final nameController = TextEditingController();
  final urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final sharedStorage = AppStorage();

  bool get isEditing => widget.app != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      // Pre-fill the form with existing app data
      nameController.text = widget.app!.name;
      urlController.text = widget.app!.url;
    }
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final name = nameController.text.trim();
      final url = urlController.text.trim();

      if (isEditing) {
        // Update existing app
        final updatedApp = App(
          id: widget.app!.id,
          name: name,
          url: url.isNotEmpty ? url : '',
        );
        await sharedStorage.updateApp(updatedApp);
      } else {
        // Add new app
        final newApp = App(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          url: url.isNotEmpty ? url : '',
        );
        await sharedStorage.addApp(newApp);
      }
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate successful operation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'App updated successfully' : 'App added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${isEditing ? 'updating' : 'adding'} app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit App' : 'Add New App'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: isEditing ? [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _showDeleteDialog,
            color: Colors.red[300],
          ),
        ] : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'App Name',
                          prefixIcon: Icon(Icons.apps),
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Gmail, Facebook, Twitter',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an app name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: urlController,
                        decoration: InputDecoration(
                          labelText: 'Website URL (Optional)',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
                          hintText: 'e.g., https://gmail.com',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isEditing ? 'Update App' : 'Add App',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete App'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${widget.app!.name}"? This will also delete all associated accounts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteApp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteApp() async {
    try {
      await sharedStorage.deleteApp(widget.app!.id);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('App deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 