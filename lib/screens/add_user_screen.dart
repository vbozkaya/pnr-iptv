import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class AddUserScreen extends StatefulWidget {
  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _m3uUrl = '';
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yeni Kullanıcı Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Kullanıcı Adı'),
                validator: (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
                onSaved: (v) => _name = v ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'M3U URL'),
                validator: (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
                onSaved: (v) => _m3uUrl = v ?? '',
              ),
              SizedBox(height: 24),
              if (_isLoading) CircularProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_error!, style: TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                child: Text('Ekle'),
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          _formKey.currentState?.save();
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          try {
                            await Provider.of<UserProvider>(context, listen: false)
                                .addUser(_name, _m3uUrl);
                            Navigator.pop(context);
                          } catch (e) {
                            setState(() {
                              _error = e.toString();
                              _isLoading = false;
                            });
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
} 