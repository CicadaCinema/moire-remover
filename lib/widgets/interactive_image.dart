import 'package:flutter/material.dart';

// A zoomable, pannable image which fills all available space.
class InteractiveImage extends StatelessWidget {
  const InteractiveImage({super.key, required this.child});
  final Image child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (myContext, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 8,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
