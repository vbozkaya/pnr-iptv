import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import '../widgets/tv_channel_card.dart';
import '../widgets/playlist_dialog.dart';
import '../models/channel.dart';
import 'player_screen.dart';
import 'login_screen.dart';
import '../providers/user_provider.dart';

class TvHomeScreen extends StatefulWidget {
  const TvHomeScreen({super.key});

  @override
  State<TvHomeScreen> createState() => _TvHomeScreenState();
}

class _TvHomeScreenState extends State<TvHomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tümü';
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'PNR IPTV',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
            onPressed: _showLogoutDialog,
            tooltip: 'Çıkış Yap',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurple,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'CANLI KANALLAR'),
            Tab(text: 'FİLMLER'),
            Tab(text: 'DİZİLER'),
          ],
        ),
      ),
      body: Consumer<IptvProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                strokeWidth: 4,
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Hata: ${provider.error}',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showPlaylistDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text('Playlist Ekle', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildSearchBar(provider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChannelGrid(provider.liveChannels, provider),
                    _buildChannelGrid(provider.movieChannels, provider),
                    _buildChannelGrid(provider.seriesChannels, provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(IptvProvider provider) {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: const InputDecoration(
          hintText: 'Kanal ara...',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
          prefixIcon: Icon(Icons.search, color: Colors.grey, size: 28),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        onChanged: provider.searchChannels,
      ),
    );
  }

  Widget _buildChannelGrid(List<Channel> channels, IptvProvider provider) {
    if (channels.isEmpty) {
      return const Center(
        child: Text(
          'İçerik bulunamadı',
          style: TextStyle(color: Colors.grey, fontSize: 20),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return TvChannelCard(
          key: ValueKey(channel.id),
          channel: channel,
          isFavorite: provider.isFavorite(channel.id),
          isSelected: false,
          onTap: () => _playChannel(channel),
          onFavoriteToggle: () => provider.toggleFavorite(channel),
        );
      },
    );
  }

  void _playChannel(Channel channel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(channel: channel),
      ),
    );
  }

  void _showPlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PlaylistDialog(),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap', style: TextStyle(fontSize: 20)),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal', style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<IptvProvider>(context, listen: false);
              await provider.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: const Text('Çıkış Yap', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class TvFavoritesScreen extends StatelessWidget {
  const TvFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Consumer<IptvProvider>(
        builder: (context, provider, child) {
          final favorites = provider.favorites;
          
          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'No favorite channels yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.67,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final channel = favorites[index];
              return TvChannelCard(
                channel: channel,
                isFavorite: true,
                isSelected: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(channel: channel),
                  ),
                ),
                onFavoriteToggle: () => provider.toggleFavorite(channel),
              );
            },
          );
        },
      ),
    );
  }
} 