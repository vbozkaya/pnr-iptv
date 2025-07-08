import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/iptv_provider.dart';
import '../widgets/channel_card.dart';
import '../widgets/playlist_dialog.dart';
import '../models/channel.dart';
import 'player_screen.dart';
import 'login_screen.dart';
import '../providers/user_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _showLogoutDialog,
            tooltip: 'Çıkış Yap',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepPurple,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
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
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hata:  ${provider.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showPlaylistDialog(context),
                    child: const Text('Playlist Ekle'),
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
                    _buildLiveChannelsMasterDetail(provider),
                    _buildFlatChannelList(provider.movieChannels, provider),
                    _buildFlatChannelList(provider.seriesChannels, provider),
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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Kanal ara...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: provider.searchChannels,
      ),
    );
  }

  Widget _buildLiveChannelsMasterDetail(IptvProvider provider) {
    final Map<String, List<Channel>> groupedChannels = {};
    for (final channel in provider.liveChannels) {
      final category = provider.getChannelCategory(channel);
      groupedChannels.putIfAbsent(category, () => []).add(channel);
    }
    final sortedCategories = groupedChannels.keys.toList()
      ..sort((a, b) {
        final priority = {
          'TR Ulusal': 1,
          'TR Beinsport': 2,
          'TR Haber': 3,
          'TR Spor': 4,
          'TR Eğlence': 5,
          'TR Çocuk': 6,
          'TR Müzik': 7,
          'TR Belgesel': 8,
          'TR Genel': 9,
          'Canlı Film': 10,
          'Canlı Dizi': 11,
          'Yabancı Kanallar': 12,
        };
        final aPriority = priority[a] ?? 999;
        final bPriority = priority[b] ?? 999;
        return aPriority.compareTo(bPriority);
      });
    // Varsayılan seçili kategori ilk kategori olsun
    final selected = _selectedCategory.isNotEmpty && groupedChannels.containsKey(_selectedCategory)
        ? _selectedCategory
        : (sortedCategories.isNotEmpty ? sortedCategories[0] : '');
    if (_selectedCategory != selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedCategory = selected;
        });
      });
    }
    return Row(
      children: [
        // Sol: Kategori listesi
        Container(
          width: 220,
          color: Colors.grey[900],
          child: ListView.builder(
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final category = sortedCategories[index];
              final isSelected = category == _selectedCategory;
              return ListTile(
                selected: isSelected,
                selectedTileColor: Colors.deepPurple.withOpacity(0.2),
                leading: Icon(_getCategoryIcon(category), color: isSelected ? Colors.deepPurple : Colors.white),
                title: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.deepPurple : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              );
            },
          ),
        ),
        // Sağ: Seçili kategorinin kanalları
        Expanded(
          child: _buildChannelList(
            groupedChannels[_selectedCategory] ?? [],
            provider,
          ),
        ),
      ],
    );
  }

  Widget _buildChannelList(List<Channel> channels, IptvProvider provider) {
    if (channels.isEmpty) {
      return const Center(
        child: Text(
          'İçerik bulunamadı',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    
    // Sadece kanal listesini göster, kategori başlığı olmadan
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return ChannelCard(
          key: ValueKey(channel.id),
          channel: channel,
          isFavorite: provider.isFavorite(channel.id),
          onTap: () => _playChannel(channel),
          onFavoriteToggle: () => provider.toggleFavorite(channel),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'TR Ulusal':
        return Icons.tv;
      case 'TR Beinsport':
        return Icons.sports_soccer;
      case 'TR Haber':
        return Icons.article;
      case 'TR Spor':
        return Icons.sports;
      case 'TR Eğlence':
        return Icons.celebration;
      case 'TR Çocuk':
        return Icons.child_care;
      case 'TR Müzik':
        return Icons.music_note;
      case 'TR Belgesel':
        return Icons.nature;
      case 'TR Genel':
        return Icons.live_tv;
      case 'Canlı Film':
        return Icons.movie;
      case 'Canlı Dizi':
        return Icons.tv;
      case 'Yabancı Kanallar':
        return Icons.language;
      default:
        return Icons.category;
    }
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

  void _showAllChannelsInCategory(BuildContext context, String category, List<Channel> channels, IptvProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: Colors.deepPurple,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Channels list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: channels.length,
                itemBuilder: (context, index) {
                  final channel = channels[index];
                  return ChannelCard(
                    key: ValueKey(channel.id),
                    channel: channel,
                    isFavorite: provider.isFavorite(channel.id),
                    onTap: () {
                      Navigator.of(context).pop();
                      _playChannel(channel);
                    },
                    onFavoriteToggle: () => provider.toggleFavorite(channel),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
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
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatChannelList(List<Channel> channels, IptvProvider provider) {
    if (channels.isEmpty) {
      return const Center(
        child: Text(
          'İçerik bulunamadı',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return ChannelCard(
          key: ValueKey(channel.id),
          channel: channel,
          isFavorite: provider.isFavorite(channel.id),
          onTap: () => _playChannel(channel),
          onFavoriteToggle: () => provider.toggleFavorite(channel),
        );
      },
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<IptvProvider>(
        builder: (context, provider, child) {
          final favorites = provider.favorites;
          
          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'No favorite channels yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final channel = favorites[index];
              return ChannelCard(
                channel: channel,
                isFavorite: true,
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