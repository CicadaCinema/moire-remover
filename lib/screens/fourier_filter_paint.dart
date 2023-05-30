import 'dart:io';

import 'package:flutter/material.dart';

class FilterPaintPage extends StatefulWidget {
  const FilterPaintPage({
    super.key,
    required this.inputImage,
  });
  final File inputImage;

  @override
  State<FilterPaintPage> createState() => _FilterPaintPageState();
}

class _FilterPaintPageState extends State<FilterPaintPage> {
  @override
  void initState() {
    super.initState();
    print('You have chosen ${widget.inputImage.path}');
    // compute Fourier transform here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paint your filter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('You have chosen ${widget.inputImage.path}'),
          ],
        ),
      ),
    );
  }
}
