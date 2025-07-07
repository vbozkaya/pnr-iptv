import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';

class TvChannelCard extends StatefulWidget {
  final Channel channel;
  final bool isFavorite;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const TvChannelCard({
    super.key,
    required this.channel,
    required this.isFavorite,
    required this.isSelected,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  State<TvChannelCard> createState() => _TvChannelCardState();
}

class _TvChannelCardState extends State<TvChannelCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: GestureDetector(
        onTap: () {
          final url = widget.channel.streamUrl;
          if (url.isEmpty || !(url.startsWith('http://') || url.startsWith('https://'))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Geçersiz veya desteklenmeyen yayın linki'), backgroundColor: Colors.red),
            );
            return;
          }
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused || widget.isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: _isFocused || widget.isSelected ? 3 : 0,
            ),
            boxShadow: _isFocused || widget.isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 200,
              height: 120,
              color: Colors.grey[900],
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildChannelLogo(),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildChannelInfo(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelLogo() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[800],
      ),
      child: (widget.channel.logoUrl != null && widget.channel.logoUrl!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: widget.channel.logoUrl!,
              fit: BoxFit.contain,
              placeholder: (context, url) => Container(
                color: Colors.grey[700],
                child: const Icon(
                  Icons.tv,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[700],
                child: const Icon(
                  Icons.tv,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
            )
          : Container(
              color: Colors.grey[700],
              child: const Icon(
                Icons.tv,
                color: Colors.grey,
                size: 32,
              ),
            ),
    );
  }

  Widget _buildChannelInfo() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.channel.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorite ? Colors.red : Colors.grey,
                  size: 16,
                ),
                onPressed: widget.onFavoriteToggle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (widget.channel.category != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.channel.category!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
} 