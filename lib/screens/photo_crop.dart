import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

import '../theme.dart';

/// In-app image crop screen (pure Dart via crop_your_image).
/// No native cropper, no AndroidManifest / theme changes required.
/// Pops with the cropped image bytes (Uint8List) on Done, or null if cancelled.
class PhotoCropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const PhotoCropScreen({super.key, required this.imageBytes});

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final CropController _controller = CropController();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Crop Photo',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Done',
            onPressed: _busy
                ? null
                : () {
                    setState(() => _busy = true);
                    _controller.crop();
                  },
          ),
        ],
      ),
      body: Crop(
        image: widget.imageBytes,
        controller: _controller,
        aspectRatio: 1,
        interactive: true,
        baseColor: Colors.black,
        maskColor: Colors.black.withOpacity(0.55),
        progressIndicator:
            const CircularProgressIndicator(color: Colors.white),
        cornerDotBuilder: (size, edgeAlignment) =>
            const DotControl(color: Colors.white),
        onCropped: (result) {
          switch (result) {
            case CropSuccess(:final croppedImage):
              if (mounted) Navigator.pop(context, croppedImage);
            case CropFailure(:final cause):
              if (mounted) {
                setState(() => _busy = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Crop failed: $cause')),
                );
              }
          }
        },
      ),
    );
  }
}
