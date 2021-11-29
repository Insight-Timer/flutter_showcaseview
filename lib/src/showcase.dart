import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'custom_paint.dart';
import 'get_position.dart';
import 'layout_overlays.dart';
import 'showcase_widget.dart';
import 'tooltip_widget.dart';

class Showcase extends StatefulWidget {
  final Widget child;
  final String? title;
  final String? description;
  final ShapeBorder? shapeBorder;
  final TextStyle? titleTextStyle;
  final TextStyle? descTextStyle;
  final EdgeInsets contentPadding;
  final GlobalKey key;
  final Color overlayColor;
  final double overlayOpacity;
  final Widget? container;
  final Color showcaseBackgroundColor;
  final Color textColor;
  final bool? showArrow;
  final double? height;
  final double? width;
  final VoidCallback? onToolTipClick;
  final VoidCallback? onTargetClick;
  final bool? disposeOnTap;
  final bool hideTooltip;
  final ArrowType type;
  final Duration animationDuration;

  const Showcase({
    required this.key,
    required this.child,
    this.title,
    required this.description,
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
    this.hideTooltip = true,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 8),
    this.onToolTipClick,
    this.type = ArrowType.up,
    this.animationDuration = const Duration(milliseconds: 200),
  })  : height = null,
        width = null,
        container = null,
        assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0, "overlay opacity should be >= 0.0 and <= 1.0."),
        assert(onTargetClick == null ? true : (disposeOnTap == null ? false : true),
            "disposeOnTap is required if you're using onTargetClick"),
        assert(disposeOnTap == null ? true : (onTargetClick == null ? false : true),
            "onTargetClick is required if you're using disposeOnTap"),
        assert(
          title != null ||
              showArrow != null ||
              description != null ||
              shapeBorder != null ||
              titleTextStyle != null ||
              descTextStyle != null ||
              shapeBorder != null,
        );

  const Showcase.withWidget({
    required this.key,
    required this.child,
    required this.container,
    required this.height,
    required this.width,
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
    this.hideTooltip = true,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 8),
    this.type = ArrowType.up,
    this.animationDuration = const Duration(milliseconds: 200),
  })  : showArrow = false,
        onToolTipClick = null,
        assert(overlayOpacity >= 0.0 && overlayOpacity <= 1.0, "overlay opacity should be >= 0.0 and <= 1.0."),
        assert(title != null ||
            description != null ||
            shapeBorder != null ||
            titleTextStyle != null ||
            descTextStyle != null);

  @override
  _ShowcaseState createState() => _ShowcaseState();
}

class _ShowcaseState extends State<Showcase> with TickerProviderStateMixin {
  bool _showShowCase = false;
  Timer? timer;
  late GetPosition position;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
      reverseDuration: widget.animationDuration,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(curve: Curves.easeInCubic, parent: _controller));

    position = GetPosition(key: widget.key);
  }

  @override
  void dispose() {
    _controller.dispose();
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
    final activeStep = ShowCaseWidget.activeTargetWidget(context);
    setState(() {
      _showShowCase = activeStep == widget.key;
    });

    if (activeStep == widget.key) {
      final showCaseWidget = ShowCaseWidget.of(context);
      if (showCaseWidget != null && showCaseWidget.autoPlay) {
        timer = Timer(Duration(seconds: showCaseWidget.autoPlayDelay.inSeconds), () {
          _nextIfAny();
        });
      }
    }

    WidgetsBinding.instance?.addPostFrameCallback((_) => _controller.forward(from: 0));
  }

  void hideOverlay(VoidCallback? callback) {
    _controller.reverse();
    Future<void>.delayed(widget.animationDuration).then((_) => callback?.call());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return _showShowCase
        ? AnchoredOverlay(
            overlayBuilder: (BuildContext context, Rect rectBound, Offset offset) =>
                buildOverlayOnTarget(offset, rectBound.size, rectBound, size),
            showOverlay: _showShowCase,
            child: widget.child,
          )
        : widget.child;
  }

  void _nextIfAny() {
    if (timer != null && timer!.isActive) {
      final showcaseWidget = ShowCaseWidget.of(context);
      if (showcaseWidget != null && showcaseWidget.autoPlayLockEnable) {
        return;
      }
      timer?.cancel();
    } else if (timer != null && !timer!.isActive) {
      timer = null;
    }
    hideOverlay(() {
      ShowCaseWidget.of(context)?.completed(widget.key);
    });
  }

  // ignore: unused_element
  void _getOnTargetTap() {
    if (widget.disposeOnTap == true) {
      ShowCaseWidget.of(context)?.dismiss();
      widget.onTargetClick?.call();
    } else {
      (widget.onTargetClick ?? _nextIfAny).call();
    }
  }

  void _getOnTooltipTap() {
    if (widget.disposeOnTap == true) {
      ShowCaseWidget.of(context)?.dismiss();
    }
    widget.onToolTipClick?.call();
  }

  Widget buildOverlayOnTarget(
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
                if (widget.hideTooltip && !_controller.isAnimating) {
                  _nextIfAny();
                }
              },
              child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: CustomPaint(
                        painter: ShapePainter(
                          opacity: widget.overlayOpacity,
                          rect: scaleRect(position.getRect(), _animation.value),
                          shapeBorder: widget.shapeBorder,
                          color: widget.overlayColor.withOpacity(_animation.value),
                        ),
                      ),
                    );
                  }),
            ),
            FadeTransition(
              opacity: _animation,
              child: ToolTipWidget(
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
            ),
          ],
        ),
      );

  Rect scaleRect(Rect rect, double scale) {
    return Rect.fromCenter(center: rect.center, width: rect.width * scale, height: rect.height * scale);
  }
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
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
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
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
