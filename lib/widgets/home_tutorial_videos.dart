import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'video_player_page.dart';

class HomeTutorialVideos extends StatelessWidget {
  const HomeTutorialVideos({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            tr('home_tutorials_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140, // Fixed height for a "Big" look
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildVideoCard(context, tr('home_video_book'), 'dQw4w9WgXcQ'),
              const SizedBox(width: 12),
              _buildVideoCard(context, tr('home_video_manage'), '9bZkp7q19f0'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(BuildContext context, String title, String id) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VideoPlayerPage(title: title, videoId: id)),
      ),
      child: Container(
        width: 240, // Makes them look wide and professional like YouTube
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage('https://img.youtube.com/vi/$id/maxresdefault.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}