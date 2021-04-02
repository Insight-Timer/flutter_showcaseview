import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'package:showcaseview/showcaseview.dart';
import 'package:showcaseview/custom_paint.dart';
import 'get_position.dart';
import 'layout_overlays.dart';
import 'tooltip_widget.dart';

class Showcase extends StatefulWidget {
  final Widget child;
  final String title;
  final String description;
  final ShapeBorder shapeBorder;
  final TextStyle titleTextStyle;
  final TextStyle descTextStyle;
  final EdgeInsets contentPadding;
  final GlobalKey key;
  final Color overlayColor;
  final double overlayOpacity;
  final Widget container;
  final Color showcaseBackgroundColor;
  final Color textColor;
  final bool showArrow;
  final double height;
  final double width;
  final VoidCallback onToolTipClick;
  final VoidCallback onTargetClick;
  final bool disposeOnTap;
  final bool hideTooltip;
  final ArrowType type;

  const Showcase({
    @required this.key,
    @required this.child,
    this.title,
    @required this.description,
    this.shapeBorder,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.75,
    this.titleTextStyle,
    this.descTextStyle,
    this.showcaseBackgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.showArrow = true,
    this.onTargetClick,
    this.disposeOnTap,
    this.hideTooltip = false,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 8),
    this.onToolTipClick,
    this.type = ArrowType.up,
  })  : height = null,
        width = null,
        container = null,
        assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0, "overlay opacity should be >= 0.0 and <= 1.0."),
        assert(onTargetClick == null ? true : (disposeOnTap == null ? false : true),
            "disposeOnTap is required if you're using onTargetClick"),
        assert(disposeOnTap == null ? true : (onTargetClick == null ? false : true),
            "onTargetClick is required if you're using disposeOnTap"),
        assert(
          key != null ||
              child != null ||
              title != null ||
              showArrow != null ||
              description != null ||
              shapeBorder != null ||
              overlayColor != null ||
              titleTextStyle != null ||
              descTextStyle != null ||
              showcaseBackgroundColor != null ||
              textColor != null ||
              shapeBorder != null,
        );

  const Showcase.withWidget({
    this.key,
    @required this.child,
    @required this.container,
    @required this.height,
    @required this.width,
    this.title,
    this.description,
    this.shapeBorder,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.75,
    this.titleTextStyle,
    this.descTextStyle,
    this.showcaseBackgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.onTargetClick,
    this.disposeOnTap,
    this.hideTooltip,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 8),
    this.type = ArrowType.up,
  })  : this.showArrow = false,
        this.onToolTipClick = null,
        assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0, "overlay opacity should be >= 0.0 and <= 1.0."),
        assert(key != null ||
            child != null ||
            title != null ||
            description != null ||
            shapeBorder != null ||
            overlayColor != null ||
            titleTextStyle != null ||
            descTextStyle != null ||
            showcaseBackgroundColor != null ||
            textColor != null ||
            shapeBorder != null);

  @override
  _ShowcaseState createState() => _ShowcaseState();
}

class _ShowcaseState extends State<Showcase> {
  bool _showShowCase = false;
  Timer timer;
  GetPosition position;

  @override
  void initState() {
    super.initState();

    position = GetPosition(key: widget.key);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showOverlay();
  }

  ///
  /// show overlay if there is any target widget
  ///
  void showOverlay() {
    GlobalKey activeStep = ShowCaseWidget.activeTargetWidget(context);
    setState(() {
      _showShowCase = activeStep == widget.key;
    });

    if (activeStep == widget.key) {
      if (ShowCaseWidget.of(context).autoPlay) {
        timer = Timer(Duration(seconds: ShowCaseWidget.of(context).autoPlayDelay.inSeconds), () {
          _nextIfAny();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AnchoredOverlay(
      overlayBuilder: (BuildContext context, Rect rectBound, Offset offset) =>
          buildOverlayOnTarget(offset, rectBound.size, rectBound, size),
      showOverlay: true,
      child: widget.child,
    );
  }

  void _nextIfAny() {
    if (timer != null && timer.isActive) {
      if (ShowCaseWidget.of(context).autoPlayLockEnable) {
        return;
      }
      timer.cancel();
    } else if (timer != null && !timer.isActive) {
      timer = null;
    }
    ShowCaseWidget.of(context).completed(widget.key);
  }

  // ignore: unused_element
  void _getOnTargetTap() {
    if (widget.disposeOnTap == true) {
      ShowCaseWidget.of(context).dismiss();
      widget.onTargetClick();
    } else {
      (widget.onTargetClick ?? _nextIfAny)?.call();
    }
  }

  void _getOnTooltipTap() {
    if (widget.disposeOnTap == true) {
      ShowCaseWidget.of(context).dismiss();
    }
    widget.onToolTipClick?.call();
  }

  buildOverlayOnTarget(
    Offset offset,
    Size size,
    Rect rectBound,
    Size screenSize,
  ) =>
      Visibility(
        visible: _showShowCase,
        maintainAnimation: true,
        maintainState: true,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                if (widget.hideTooltip) {
                  _nextIfAny();
                }
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: CustomPaint(
                  painter: ShapePainter(
                    opacity: widget.overlayOpacity,
                    rect: position.getRect(),
                    shapeBorder: widget.shapeBorder,
                    color: widget.overlayColor,
                  ),
                ),
              ),
            ),
            ToolTipWidget(
              position: position,
              offset: offset,
              screenSize: screenSize,
              title: widget.title,
              description: widget.description,
              titleTextStyle: widget.titleTextStyle,
              descTextStyle: widget.descTextStyle,
              container: widget.container,
              tooltipColor: widget.showcaseBackgroundColor,
              textColor: widget.textColor,
              showArrow: widget.showArrow,
              contentHeight: widget.height,
              contentWidth: widget.width,
              onTooltipTap: _getOnTooltipTap,
              contentPadding: widget.contentPadding,
              type: widget.type,
            ),
          ],
        ),
      );
}

enum ArrowType { up, down }

class TooltipShapeBorder extends ShapeBorder {
  final double arrowWidth;
  final double arrowHeight;
  final double arrowArc;
  final double radius;
  final ArrowType type;

  TooltipShapeBorder({
    this.radius = 20.0,
    this.arrowWidth = 20.0,
    this.arrowHeight = 10.0,
    this.arrowArc = 0.5,
    this.type = ArrowType.up,
  }) : assert(arrowArc <= 1.0 && arrowArc >= 0.0);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(top: arrowHeight);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) => null;

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    rect = Rect.fromPoints(rect.topLeft, rect.bottomRight - Offset(0, arrowHeight));
    // ignore: omit_local_variable_types
    double x = arrowWidth, y = arrowHeight, r = 1 - arrowArc;
    if (type == ArrowType.up) {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)))
        ..moveTo(rect.topLeft.dx + 56, rect.topCenter.dy)
        ..relativeLineTo(-x / 2 * r, -y * r)
        ..relativeQuadraticBezierTo(-x / 2 * (1 - r), y * (-1 + r), -x * (1 - r), 0)
        ..relativeLineTo(-x / 2 * r, y * r);
    } else {
      return Path()
        ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)))
        ..moveTo(rect.bottomLeft.dx + 38, rect.bottomCenter.dy)
        ..relativeLineTo(-x / 2 * r, y * r)
        ..relativeQuadraticBezierTo(-x / 2 * (1 - r), y * (1 - r), -x * (1 - r), 0)
        ..relativeLineTo(-x / 2 * r, -y * r);
    }
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
