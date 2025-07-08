import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user.dart';

class AddUserScreen extends StatefulWidget {
  final User? editingUser;
  
  const AddUserScreen({Key? key, this.editingUser}) : super(key: key);

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
  void initState() {
    super.initState();
    // Eğer düzenleme modundaysa, mevcut bilgileri yükle
    if (widget.editingUser != null) {
      _name = widget.editingUser!.name;
      _m3uUrl = widget.editingUser!.m3uUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingUser != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Kullanıcı Düzenle' : 'Yeni Kullanıcı Ekle'),
      ),
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
                initialValue: isEditing ? _name : null,
                controller: isEditing ? TextEditingController(text: _name) : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'M3U URL'),
                validator: (v) => v == null || v.isEmpty ? 'Zorunlu alan' : null,
                onSaved: (v) => _m3uUrl = v ?? '',
                initialValue: isEditing ? _m3uUrl : null,
                controller: isEditing ? TextEditingController(text: _m3uUrl) : null,
              ),
              SizedBox(height: 24),
              if (_isLoading) CircularProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_error!, style: TextStyle(color: Colors.red)),
                ),
              ElevatedButton(
                child: Text(isEditing ? 'Güncelle' : 'Ekle'),
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
                            final userProvider = Provider.of<UserProvider>(context, listen: false);
                            
                            if (isEditing) {
                              // Düzenleme modu - kullanıcıyı güncelle
                              await userProvider.updateUser(
                                widget.editingUser!.id,
                                _name,
                                _m3uUrl,
                              );
                            } else {
                              // Yeni kullanıcı ekleme modu
                              await userProvider.addUser(_name, _m3uUrl);
                            }
                            
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