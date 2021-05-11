import 'dart:io';
import 'dart:ui';
import 'package:flutter/widgets.dart';

/// A class to represent PDF page
/// [imgPath], path of the image (pdf page)
/// [num], page number
/// [onZoomChanged], function called when zoom is changed
/// [zoomSteps], number of zoom steps on double tap
/// [minScale] minimum zoom scale
/// [maxScale] maximum zoom scale
/// [panLimit] limit for pan
class PDFPage extends StatefulWidget {
  final String imgPath;
  final int num;
  final Function(double)? onZoomChanged;
  final int? zoomSteps;
  final double? minScale;
  final double? maxScale;
  final double? panLimit;

  PDFPage(
    this.imgPath,
    this.num, {
    this.onZoomChanged,
    this.zoomSteps,
    this.minScale,
    this.maxScale,
    this.panLimit,
  });

  @override
  _PDFPageState createState() => _PDFPageState();
}

class _PDFPageState extends State<PDFPage> {
  @override
  void didUpdateWidget(PDFPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imgPath != widget.imgPath) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: InteractiveViewer(
        maxScale: widget.maxScale ?? 3,
        minScale: widget.minScale ?? 0.5,
        boundaryMargin: EdgeInsets.all(MediaQuery.of(context).size.width),
        child: Image.file(File(widget.imgPath)),
      ),
    );
  }
}
