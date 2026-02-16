import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoPlayerPage extends StatefulWidget {
  final String title;
  final String videoId;

  const VideoPlayerPage({super.key, required this.title, required this.videoId});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        // This is the most important parameter for PWAs
        pointerEvents: PointerEvents.auto, 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // YoutubePlayerScaffold is REQUIRED for production PWA deployment
    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              player, // This now contains the production-ready IFrame
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}