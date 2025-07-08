import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/iptv_provider.dart';
import '../models/user.dart';
import 'user_selection_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNameController = TextEditingController();
  final _m3uController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dnsController = TextEditingController();
  
  bool _isLoading = false;
  int _selectedTabIndex = 0; // 0: Mevcut Oturumlar, 1: M3U, 2: API

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = 0;
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _m3uController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _dnsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Logo ve Başlık
                  _buildHeader(),
                  // Kurulum Seçenekleri
                  _buildSetupOptions(),
                  // Form
                  _buildForm(),
                  // Giriş Butonu
                  _buildLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(60),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.tv,
            size: 60,
            color: Colors.deepPurple,
          ),
        ),
        const Text(
          'PNR IPTV',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Text(
          'Televizyon kanallarınızı izleyin',
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSetupOptions() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? Colors.deepPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mevcut Oturumlar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTabIndex == 0 ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? Colors.deepPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'M3U Playlist',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTabIndex == 1 ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 2 ? Colors.deepPurple : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'API Kurulum',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTabIndex == 2 ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    if (_selectedTabIndex == 0) {
      return _buildExistingSessionsTab();
    } else if (_selectedTabIndex == 1) {
      return _buildM3uTab();
    } else {
      return _buildApiTab();
    }
  }

  Widget _buildExistingSessionsTab() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final sessions = userProvider.sessions;
        
        if (sessions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Henüz oturum yok',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'M3U Playlist veya API Kurulum sekmelerinden\nbir oturum ekleyin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Mevcut Oturumlar (${sessions.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...sessions.map((session) => _buildSessionCard(session, userProvider)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(User session, UserProvider userProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.grey[900],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(
            session.name[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          session.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Hesap: ${session.name}',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.green),
              onPressed: () => _selectSession(session),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteSession(session, userProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildM3uTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Hesap Adı
            TextFormField(
              controller: _accountNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Hesap Adı',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen hesap adını girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // M3U URL
            TextFormField(
              controller: _m3uController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'M3U Playlist URL',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen M3U URL girin';
                }
                if (!(Uri.tryParse(value)?.hasScheme ?? false)) {
                  return 'Geçerli bir URL girin';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Hesap Adı
            TextFormField(
              controller: _accountNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Hesap Adı',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen hesap adını girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // DNS
            TextFormField(
              controller: _dnsController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'DNS',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen DNS girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Kullanıcı Adı
            TextFormField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Kullanıcı Adı',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen kullanıcı adını girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Şifre
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Şifre',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Lütfen şifreyi girin';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isLoading ? null : _onLoginPressed,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  _selectedTabIndex == 0 ? 'Mevcut Oturumlar' : 
                  _selectedTabIndex == 1 ? 'M3U Playlist Ekle' : 'API Hesabı Ekle',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    if (_selectedTabIndex == 0) {
      // Mevcut oturumlar sekmesinde bir şey yapmaya gerek yok
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userProvider = context.read<UserProvider>();
      
      if (_selectedTabIndex == 1) {
        // M3U Playlist ekleme
        await userProvider.addUser(
          _accountNameController.text.trim(),
          _m3uController.text.trim(),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('M3U hesabı başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (_selectedTabIndex == 2) {
        // API hesabı ekleme
        final dns = _dnsController.text.trim();
        final username = _usernameController.text.trim();
        final password = _passwordController.text.trim();
        
        // API URL'ini oluştur
        final apiUrl = 'http://$dns/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
        
        await userProvider.addUser(
          _accountNameController.text.trim(),
          apiUrl,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API hesabı başarıyla eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Form alanlarını temizle
      _accountNameController.clear();
      _m3uController.clear();
      _usernameController.clear();
      _passwordController.clear();
      _dnsController.clear();
      
      // Sessions listesini yenile
      await userProvider.refreshAllData();
      
      // Mevcut oturumlar sekmesine geç
      setState(() => _selectedTabIndex = 0);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectSession(User session) async {
    setState(() => _isLoading = true);
    
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.selectUser(session);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Oturum açılırken hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSession(User session, UserProvider userProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oturumu Sil'),
        content: Text('${session.name} oturumunu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await userProvider.removeUser(session.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${session.name} oturumu silindi'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
} 