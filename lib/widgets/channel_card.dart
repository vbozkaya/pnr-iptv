import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../services/cache_service.dart';

class ChannelCard extends StatelessWidget {
  final Channel channel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ChannelCard({
    super.key,
    required this.channel,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildChannelLogo(),
              const SizedBox(width: 12),
              Expanded(
                child: _buildChannelInfo(),
              ),
              _buildFavoriteButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.tv,
          color: Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildChannelInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          channel.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (channel.category != null) ...[
          const SizedBox(height: 4),
          Text(
            channel.category!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (channel.description != null) ...[
          const SizedBox(height: 4),
          Text(
            channel.description!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.grey,
      ),
      onPressed: onFavoriteToggle,
    );
  }
} 