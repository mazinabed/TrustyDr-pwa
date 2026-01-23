import 'package:flutter/material.dart';

class ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class CenterActionGrid extends StatelessWidget {
  final List<ActionItem> items;

  const CenterActionGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      int count = 3;
    

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: count,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.1,
        children: items.map(_buildTile).toList(),
      );
    });
  }

Widget _buildTile(ActionItem item) {
  return InkWell(
    onTap: item.onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      height: 96, // 👈 control height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 26, color: Colors.white),
          const SizedBox(height: 6),
         Text(
  item.label,
  textAlign: TextAlign.center,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(
    color: Colors.white,
    fontSize: 12, // 👈 slightly smaller
    fontWeight: FontWeight.w600,
    height: 1.15, // 👈 tighter line spacing
  ),
),

       
        ],
      ),
    ),
  );
}


}
