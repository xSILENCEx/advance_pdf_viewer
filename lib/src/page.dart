import 'dart:io';
import 'package:flutter/material.dart';
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
  final bool fillWidth;

  PDFPage(
    this.imgPath,
    this.num, {
    this.onZoomChanged,
    this.zoomSteps,
    this.minScale,
    this.maxScale,
    this.panLimit,
    this.fillWidth = false,
  });

  @override
  _PDFPageState createState() => _PDFPageState();
}

class _PDFPageState extends State<PDFPage> {
  @override
  void didUpdateWidget(PDFPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imgPath != widget.imgPath || oldWidget.fillWidth != widget.fillWidth) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget img = Image.file(
      File(widget.imgPath),
      alignment: widget.fillWidth ? Alignment.topCenter : Alignment.center,
    );

    if (widget.fillWidth) img = SingleChildScrollView(child: img);

    return ClipRect(
      child: InteractiveViewer(
        alignPanAxis: true,
        maxScale: widget.maxScale ?? 5,
        minScale: widget.minScale ?? 0.2,
        child: img,
      ),
    );
  }
}
