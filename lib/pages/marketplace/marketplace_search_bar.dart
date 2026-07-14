import 'dart:async';

import 'package:flutter/material.dart';

/// Shared Marketplace search field — trailing clear ("x") action lives
/// INSIDE the field via [InputDecoration.suffixIcon], visible only when
/// there's text, and never reserves layout space when hidden (a bare
/// `IconButton` swapped for `SizedBox.shrink()`, not an invisible one).
/// Clearing restores the full (unfiltered) results via [onChanged] firing
/// with an empty string, debounced identically to normal typing so it can't
/// race a still-pending keystroke update.
class MarketplaceSearchBar extends StatefulWidget {
  const MarketplaceSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 300),
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final Duration debounce;

  @override
  State<MarketplaceSearchBar> createState() => _MarketplaceSearchBarState();
}

class _MarketplaceSearchBarState extends State<MarketplaceSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    setState(() {}); // toggles the clear-button's visibility immediately
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () => widget.onChanged(value));
  }

  void _clear() {
    _controller.clear();
    _debounceTimer?.cancel();
    setState(() {});
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: _handleChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: Colors.black45,
                  onPressed: _clear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
