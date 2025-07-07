import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/iptv_provider.dart';
import '../models/user.dart';
import 'add_user_screen.dart';

class UserSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Kullanıcı Seç veya Ekle')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Daha önce eklediğiniz kullanıcılar aşağıda listelenir. Yeni kullanıcı ekleyebilir veya bir kullanıcıya tıklayarak oturum açabilirsiniz.',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: userProvider.users.length,
              itemBuilder: (context, index) {
                final user = userProvider.users[index];
                return Card(
                  color: userProvider.activeUser?.id == user.id ? Colors.blue[50] : null,
                  child: ListTile(
                    title: Text(user.name),
                    subtitle: Text('Hesap: ${user.name}'),
                    onTap: () async {
                      final iptvProvider = Provider.of<IptvProvider>(context, listen: false);
                      await userProvider.selectUser(user, iptvProvider: iptvProvider);
                      // Başarılıysa ana ekrana geçiş LoadingAndUpdateScreen ile olacak
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Update butonu - Yayın içeriğini güncelle
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.green),
                          tooltip: 'Yayın İçeriğini Güncelle',
                          onPressed: () async {
                            final iptvProvider = Provider.of<IptvProvider>(context, listen: false);
                            await userProvider.selectUser(user, iptvProvider: iptvProvider);
                            // Playlist'i yeniden yükle
                            await iptvProvider.loadPlaylistFromUrl(user.m3uUrl);
                          },
                        ),
                        // Edit butonu - Kullanıcı bilgilerini düzenle
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          tooltip: 'Kullanıcı Bilgilerini Düzenle',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddUserScreen(editingUser: user),
                              ),
                            );
                          },
                        ),
                        // Delete butonu
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Kullanıcıyı Sil',
                          onPressed: () async {
                            await userProvider.removeUser(user.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (userProvider.isLoading) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          if (userProvider.error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(userProvider.error!, style: TextStyle(color: Colors.red)),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Yeni Kullanıcı Ekle'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddUserScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 