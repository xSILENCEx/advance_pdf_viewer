import 'package:flutter/material.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:numberpicker/numberpicker.dart';

import 'safe_value_notifier.dart';

/// enum to describe indicator position
enum IndicatorPosition { topLeft, topRight, bottomLeft, bottomRight }

/// PDFViewer, a inbuild pdf viewer, you can create your own too.
/// [document] an instance of `PDFDocument`, document to be loaded
/// [indicatorText] color of indicator text
/// [indicatorBackground] color of indicator background
/// [pickerButtonColor] the picker button background color
/// [pickerIconColor] the picker button icon color
/// [indicatorPosition] position of the indicator position defined by `IndicatorPosition` enum
/// [showIndicator] show,hide indicator
/// [showPicker] show hide picker
/// [showNavigation] show hide navigation bar
/// [toolTip] tooltip, instance of `PDFViewerTooltip`
/// [enableSwipeNavigation] enable,disable swipe navigation
/// [scrollDirection] scroll direction horizontal or vertical
/// [lazyLoad] lazy load pages or load all at once
/// [controller] page controller to control page viewer
/// [zoomSteps] zoom steps for pdf page
/// [minScale] minimum zoom scale for pdf page
/// [maxScale] maximum zoom scale for pdf page
/// [panLimit] pan limit for pdf page
/// [onPageChanged] function called when page changes
///
class PDFViewer extends StatefulWidget {
  final PDFDocument document;
  final Color indicatorText;
  final Color indicatorBackground;
  final Color? pickerButtonColor;
  final Color? pickerIconColor;
  final IndicatorPosition indicatorPosition;
  final bool showIndicator;
  final bool showPicker;
  final bool showNavigation;
  final PDFViewerTooltip tooltip;
  final bool enableSwipeNavigation;
  final Axis scrollDirection;
  final bool lazyLoad;
  final PageController? controller;
  final int? zoomSteps;
  final double? minScale;
  final double? maxScale;
  final double? panLimit;
  final ValueChanged<int>? onPageChanged;
  final Color? backgroundColor;
  final bool useStackNavBar;
  final bool fillWidth;

  final Widget Function(
    BuildContext,
    int pageNumber,
    int totalPages,
    void Function({int page}) jumpToPage,
    void Function({int page}) animateToPage,
  )? navigationBuilder;
  final Widget? progressIndicator;

  PDFViewer({
    Key? key,
    required this.document,
    this.scrollDirection = Axis.horizontal,
    this.lazyLoad = true,
    this.indicatorText = Colors.white,
    this.indicatorBackground = Colors.black54,
    this.showIndicator = true,
    this.showPicker = true,
    this.showNavigation = true,
    this.enableSwipeNavigation = true,
    this.tooltip = const PDFViewerTooltip(),
    this.navigationBuilder,
    this.controller,
    this.indicatorPosition = IndicatorPosition.topRight,
    this.zoomSteps,
    this.minScale,
    this.maxScale,
    this.panLimit,
    this.progressIndicator,
    this.pickerButtonColor,
    this.pickerIconColor,
    this.onPageChanged,
    this.backgroundColor,
    this.useStackNavBar = false,
    this.fillWidth = false,
  }) : super(key: key);

  _PDFViewerState createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  final SafeValueNotifier<bool> _isLoading = SafeValueNotifier<bool>(true);
  final SafeValueNotifier<int> _pageNumber = SafeValueNotifier<int>(1);
  final Duration animationDuration = Duration(milliseconds: 200);
  final Curve animationCurve = Curves.easeIn;

  final SafeValueNotifier<List<PDFPage?>?> _pages = SafeValueNotifier<List<PDFPage?>?>(null);
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pages.value = List<PDFPage?>.generate(widget.document.count, (index) => null);
    _pageController = widget.controller ?? PageController();
    _pageNumber.value = _pageController.initialPage + 1;

    if (!widget.lazyLoad)
      widget.document.preloadPages(
        zoomSteps: widget.zoomSteps,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        fillWidth: widget.fillWidth,
      );

    _loadPage();
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _pageNumber.dispose();
    _pages.dispose();
    _pageController.dispose();
    super.dispose();
  }

  _loadPage() async {
    if (_pages.value![_pageNumber.value - 1] != null) {
      return;
    }

    _isLoading.value = true;

    final PDFPage data = await widget.document.get(
      page: _pageNumber.value,
      zoomSteps: widget.zoomSteps,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      panLimit: widget.panLimit,
      fillWidth: widget.fillWidth,
    );

    _pages.value![_pageNumber.value - 1] = data;
    _pages.value = List<PDFPage?>.from(_pages.value!);

    _isLoading.value = false;
  }

  _animateToPage({int? page}) {
    _pageController.animateToPage(page ?? _pageNumber.value - 1, duration: animationDuration, curve: animationCurve);
  }

  _jumpToPage({int? page}) {
    _pageController.jumpToPage(page ?? _pageNumber.value - 1);
  }

  _pickPage() {
    showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return NumberPicker(
            minValue: 1,
            maxValue: widget.document.count,
            value: _pageNumber.value,
            onChanged: (value) {
              _pageNumber.value = value;
              _jumpToPage();
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    Widget _content = ValueListenableBuilder<bool>(
      valueListenable: _isLoading,
      builder: (_, bool load, __) {
        return ValueListenableBuilder<List<PDFPage?>?>(
          valueListenable: _pages,
          builder: (_, List<PDFPage?>? p, __) {
            return PageView.builder(
              physics: widget.enableSwipeNavigation && !load ? null : NeverScrollableScrollPhysics(),
              onPageChanged: (page) async {
                _pageNumber.value = page + 1;

                await _loadPage();

                widget.onPageChanged?.call(page);
              },
              scrollDirection: widget.scrollDirection,
              controller: _pageController,
              itemCount: p!.length,
              itemBuilder: (context, index) => p[index] == null ? Center(child: widget.progressIndicator ?? CircularProgressIndicator()) : p[index]!,
            );
          },
        );
      },
    );

    if (widget.showIndicator || widget.useStackNavBar) {
      _content = Stack(
        children: <Widget>[
          _content,
          if (widget.showIndicator)
            ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (_, bool load, __) => load ? SizedBox.shrink() : _drawIndicator(),
            ),
          if (widget.useStackNavBar) Align(alignment: Alignment.bottomCenter, child: _buildNavBar()),
        ],
      );
    }

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: _content,
      floatingActionButton: widget.showPicker && widget.document.count > 1
          ? FloatingActionButton(
              elevation: 4.0,
              tooltip: widget.tooltip.jump,
              child: Icon(
                Icons.view_carousel,
                color: widget.pickerIconColor ?? Colors.white,
              ),
              backgroundColor: widget.pickerButtonColor ?? Colors.blue,
              onPressed: () {
                _pickPage();
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: !widget.useStackNavBar ? _buildNavBar() : const SizedBox.shrink(),
    );
  }

  Widget _drawIndicator() {
    Widget child = GestureDetector(
      onTap: widget.showPicker && widget.document.count > 1 ? _pickPage : null,
      child: Container(
        padding: EdgeInsets.only(top: 4.0, left: 16.0, bottom: 4.0, right: 16.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4.0), color: widget.indicatorBackground),
        child: ValueListenableBuilder<int>(
            valueListenable: _pageNumber,
            builder: (_, int page, __) {
              return Text(
                "$page/${widget.document.count}",
                style: TextStyle(
                  color: widget.indicatorText,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w400,
                ),
              );
            }),
      ),
    );

    switch (widget.indicatorPosition) {
      case IndicatorPosition.topLeft:
        return Positioned(top: 20, left: 20, child: child);
      case IndicatorPosition.topRight:
        return Positioned(top: 20, right: 20, child: child);
      case IndicatorPosition.bottomLeft:
        return Positioned(bottom: 20, left: 20, child: child);
      case IndicatorPosition.bottomRight:
        return Positioned(bottom: 20, right: 20, child: child);
      default:
        return Positioned(top: 20, right: 20, child: child);
    }
  }

  Widget _buildNavBar() {
    return (widget.showNavigation && widget.document.count > 1)
        ? ValueListenableBuilder<int>(
            valueListenable: _pageNumber,
            builder: (_, int p, Widget? child) {
              return ValueListenableBuilder<bool>(
                  valueListenable: _isLoading,
                  builder: (_, bool load, Widget? child) {
                    return widget.navigationBuilder != null
                        ? widget.navigationBuilder!(context, p, widget.document.count, _jumpToPage, _animateToPage)
                        : BottomAppBar(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Expanded(
                                  child: IconButton(
                                    icon: Icon(Icons.first_page),
                                    tooltip: widget.tooltip.first,
                                    onPressed: p == 1 || load
                                        ? null
                                        : () {
                                            _pageNumber.value = 1;
                                            _jumpToPage();
                                          },
                                  ),
                                ),
                                Expanded(
                                  child: IconButton(
                                    icon: Icon(Icons.chevron_left),
                                    tooltip: widget.tooltip.previous,
                                    onPressed: p == 1 || load
                                        ? null
                                        : () {
                                            _pageNumber.value = _pageNumber.value - 1;
                                            if (1 > _pageNumber.value) {
                                              _pageNumber.value = 1;
                                            }
                                            _animateToPage();
                                          },
                                  ),
                                ),
                                widget.showPicker ? Expanded(child: Text('')) : SizedBox(width: 1),
                                Expanded(
                                  child: IconButton(
                                    icon: Icon(Icons.chevron_right),
                                    tooltip: widget.tooltip.next,
                                    onPressed: p == widget.document.count || load
                                        ? null
                                        : () {
                                            _pageNumber.value = _pageNumber.value + 1;
                                            if (_pageNumber.value < 1) {
                                              _pageNumber.value = 1;
                                            }

                                            _animateToPage();
                                          },
                                  ),
                                ),
                                Expanded(
                                  child: IconButton(
                                    icon: Icon(Icons.last_page),
                                    tooltip: widget.tooltip.last,
                                    onPressed: p == widget.document.count || load
                                        ? null
                                        : () {
                                            _pageNumber.value = widget.document.count;
                                            _jumpToPage();
                                          },
                                  ),
                                ),
                              ],
                            ),
                          );
                  });
            },
          )
        : const SizedBox.shrink();
  }
}
