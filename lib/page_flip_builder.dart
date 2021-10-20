import 'dart:math';

import 'package:flutter/material.dart';

class PageFlipBuilder extends StatefulWidget {
  final WidgetBuilder frontBuilder;
  final WidgetBuilder backBuilder;
  const PageFlipBuilder({
    Key? key,
    required this.backBuilder,
    required this.frontBuilder,
  }) : super(key: key);

  @override
  _PageFlipBuilderState createState() => _PageFlipBuilderState();
}

class _PageFlipBuilderState extends State<PageFlipBuilder>
    with SingleTickerProviderStateMixin {
  bool _showFrontSide = true;
  late final AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: -1.0,
      upperBound: 1.0,
    );
    _controller.value = 0.0;
    _controller.addStatusListener(_updateStatus);
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_updateStatus);
    _controller.dispose();
    super.dispose();
  }

  void _updateStatus(AnimationStatus state) {
    if (state == AnimationStatus.completed ||
        state == AnimationStatus.dismissed) {
      _controller.value = 0.0;
      setState(() {
        _showFrontSide = !_showFrontSide;
      });
    }
  }

  void flip() {
    if (_showFrontSide) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _handDragUpdate(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    _controller.value += details.primaryDelta! / screenWidth;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handDragUpdate,
      child: AnimatedPageFlipBuilder(
        animation: _controller,
        showFrontSide: _showFrontSide,
        frontBuilder: widget.frontBuilder,
        backBuilder: widget.backBuilder,
      ),
    );
  }
}

class AnimatedPageFlipBuilder extends StatelessWidget {
  final Animation<double> animation;
  final bool showFrontSide; // we'll see how to use this later
  final WidgetBuilder frontBuilder;
  final WidgetBuilder backBuilder;

  const AnimatedPageFlipBuilder(
      {Key? key,
      required this.animation,
      required this.backBuilder,
      required this.frontBuilder,
      required this.showFrontSide})
      : super(key: key);

  bool get _isAnimationFirstHalf => animation.value.abs() < 0.5;
  double _getTilt() {
    var tilt = (animation.value - 0.5).abs() - 0.5;
    if (animation.value < -0.5) {
      tilt = 1.0 + animation.value;
    }
    return tilt * (_isAnimationFirstHalf ? -0.003 : 0.003);
  }

  double _rotationAngle() {
    final rotationValue = animation.value * pi;
    if (animation.value > 0.5) {
      return pi - rotationValue;
    } else if (animation.value > 0.5) {
      return rotationValue;
    } else {
      return -pi - rotationValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final child = _isAnimationFirstHalf
            ? frontBuilder(context)
            : backBuilder(context);
        return Transform(
          transform: Matrix4.rotationY(_rotationAngle())
            ..setEntry(3, 0, _getTilt()),
          child: child,
          alignment: Alignment.center,
        );
      },
    );
  }
}
