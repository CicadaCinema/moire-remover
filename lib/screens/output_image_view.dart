import 'package:flutter/material.dart';

class OutputImageViewPage extends StatefulWidget {
  const OutputImageViewPage({
    super.key,
    required this.outputImage,
  });
  final Image outputImage;

  @override
  State<OutputImageViewPage> createState() => _OutputImageViewPageState();
}

class _OutputImageViewPageState extends State<OutputImageViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Here is your output image'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            widget.outputImage,
          ],
        ),
      ),
    );
  }
}
