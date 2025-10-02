import 'package:flutter/material.dart';

OverlayEntry? _currentOverlay;

void showSnackbar(
  BuildContext context,
  String message, {
  Widget? icon,
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 2),
  EdgeInsets margin = const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
}) {
  _currentOverlay?.remove();

  final overlay = OverlayEntry(
    builder: (context) {
      return _AnimatedSnackbar(
        message: message,
        icon: icon,
        backgroundColor: (backgroundColor ?? Colors.black.withOpacity(0.7)),
        duration: duration,
        margin: margin,
      );
    },
  );

  Overlay.of(context, rootOverlay: true).insert(overlay);
  _currentOverlay = overlay;

  Future.delayed(duration + const Duration(milliseconds: 300), () {
    _currentOverlay?.remove();
    _currentOverlay = null;
  });
}

class _AnimatedSnackbar extends StatefulWidget {
  final String message;
  final Widget? icon;
  final Color backgroundColor;
  final Duration duration;
  final EdgeInsets margin;

  const _AnimatedSnackbar({
    required this.message,
    required this.backgroundColor,
    required this.duration,
    required this.margin,
    this.icon,
  });

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Positioned(
      bottom: widget.margin.vertical + bottomInset,
      left: widget.margin.horizontal,
      right: widget.margin.horizontal,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.icon != null) widget.icon!,
                  if (widget.icon != null) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
