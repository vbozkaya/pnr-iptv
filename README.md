# PNR IPTV

A modern Flutter IPTV application for streaming television channels from M3U playlists.

## Features

- 📺 **Channel Streaming**: Watch live TV channels from M3U playlists
- 🔍 **Search & Filter**: Search channels by name and filter by category
- ⭐ **Favorites**: Save your favorite channels for quick access
- 🎨 **Modern UI**: Beautiful Material Design 3 interface with dark/light theme support
- 📱 **Cross-Platform**: Works on Android, iOS, Windows, macOS, and Linux
- 💾 **Local Storage**: Saves favorites and playlist data locally
- 🔄 **Auto-Refresh**: Automatically updates playlists when loaded

## Screenshots

[Add screenshots here when available]

## Installation

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/pi_iptv.git
   cd pi_iptv
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## Usage

### Adding a Playlist

1. Launch the PNR IPTV application
2. Tap the "+" button (Floating Action Button)
3. Enter your M3U playlist URL
4. Tap "Add" to load the playlist

### Watching Channels

1. Browse through the channel list
2. Tap on any channel to start streaming
3. Use the video player controls to adjust playback

### Managing Favorites

1. Tap the heart icon on any channel card to add/remove from favorites
2. Access your favorites by tapping the heart icon in the app bar

### Searching and Filtering

1. Use the search bar to find specific channels
2. Use category filters to browse channels by type
3. Combine search and filters for precise results

## Supported Formats

- **M3U Playlists**: Standard M3U and M3U8 format
- **Video Streams**: HLS, DASH, and other common streaming protocols
- **Channel Metadata**: Channel names, logos, categories, and descriptions

## Architecture

The application follows a clean architecture pattern with:

- **Models**: Data classes for Channel and Playlist
- **Services**: IPTV parsing and storage services
- **Providers**: State management using Provider pattern
- **Screens**: UI screens for different app sections
- **Widgets**: Reusable UI components

## Dependencies

- `video_player`: Video playback functionality
- `chewie`: Enhanced video player UI
- `http`: Network requests for playlist loading
- `provider`: State management
- `shared_preferences`: Local data storage
- `cached_network_image`: Image caching for channel logos
- `shimmer`: Loading animations

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This application is for educational and personal use only. Users are responsible for ensuring they have the right to access and stream the content they use with this application.

## Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/yourusername/pi_iptv/issues) page
2. Create a new issue with detailed information
3. Include device information and steps to reproduce

## Roadmap

- [ ] EPG (Electronic Program Guide) support
- [ ] Multiple playlist management
- [ ] Advanced video player controls
- [ ] Channel recording functionality
- [ ] Picture-in-Picture mode
- [ ] Cast support
- [ ] Offline playlist support
- [ ] Custom themes
- [ ] Widget support
- [ ] Notification controls

## Changelog

### v1.0.0
- Initial release
- Basic M3U playlist support
- Channel streaming with video player
- Favorites management
- Search and filter functionality
- Modern Material Design 3 UI
