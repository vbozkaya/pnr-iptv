import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'add_user_screen.dart';
import 'user_selection_screen.dart';
import 'loading_and_update_screen.dart';

class StartupScreen extends StatefulWidget {
  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      Provider.of<UserProvider>(context, listen: false).loadUsers();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.activeUser != null) {
          // Oturum açık kullanıcı varsa, içerik güncellenip ana ekrana geçilecek
          return LoadingAndUpdateScreen();
        } else if (userProvider.users.isNotEmpty) {
          // Kullanıcılar varsa seçim ekranı
          return UserSelectionScreen();
        } else {
          // Hiç kullanıcı yoksa yeni kullanıcı ekle
          return AddUserScreen();
        }
      },
    );
  }
} 