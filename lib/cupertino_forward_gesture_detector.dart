import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

const double _kGestureWidth = 20.0;
const double _kMinFlingVelocity = 1.0; // Screen widths per second.
const int _kMaxDroppedSwipePageForwardAnimationTime = 800; // Milliseconds.
const int _kMaxPageBackAnimationTime = 300;

class SwipePushPageRoute<T> extends PageRoute<T> {
  final VoidCallback pushRoute;
  final Curve transitionCurve;
  final RouteTransitionsBuilder? transitionsBuilder;
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  @override
  final Duration transitionDuration;

  SwipePushPageRoute({
    required this.builder,
    required this.pushRoute,
    this.transitionCurve = Curves.fastEaseInToSlowEaseOut,
    super.settings,
    this.transitionsBuilder,
    this.maintainState = true,
    this.transitionDuration = const Duration(milliseconds: 300),
  });

  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    if (nextRoute is ModalRoute) {
      // _swipeUpPushController.transitionController = nextRoute.controller;
      // _swipeUpPushController.nextRoute = nextRoute;
    }
    super.didChangeNext(nextRoute);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is PageRoute;
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return nextRoute is PageRoute;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final bool linearTransition = isGestureInProgress(this);
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: linearTransition,
      child: SwipeGestureDetector<T>(
        enabledCallback: (type) => _isGestureEnabled<T>(this, type),
        onStartGesture: (type) => _startGesture<T>(this, type),
        child: child,
      ),
    );
  }

  static SwipeGestureController<T> _startGesture<T>(
      PageRoute<T> route, SwipeGestureType type) {
    return SwipeGestureController<T>(
      navigator: () => route.navigator,
      controller: () => route.controller,
    );
  }

  static bool _isGestureEnabled<T>(PageRoute<T> route, SwipeGestureType type) {
    // If there's nothing to go back to, then obviously we don't support
    // the back gesture.
    if (route.isFirst) {
      return false;
    }
    // If the route wouldn't actually pop if we popped it, then the gesture
    // would be really confusing (or would skip internal routes), so disallow it.
    if (route.willHandlePopInternally) {
      return false;
    }
    // If attempts to dismiss this route might be vetoed such as in a page
    // with forms, then do not allow the user to dismiss the route with a swipe.
    if (route.hasScopedWillPopCallback ||
        route.popDisposition == RoutePopDisposition.doNotPop) {
      return false;
    }
    // Fullscreen dialogs aren't dismissible by back swipe.
    if (route.fullscreenDialog) {
      return false;
    }
    // If we're in an animation already, we cannot be manually swiped.
    if (route.animation!.status != AnimationStatus.completed) {
      return false;
    }
    // If we're being popped into, we also cannot be swiped until the pop above
    // it completes. This translates to our secondary animation being
    // dismissed.
    if (route.secondaryAnimation!.status != AnimationStatus.dismissed) {
      return false;
    }
    // If we're in a gesture already, we cannot start another.
    if (isGestureInProgress(route)) {
      return false;
    }

    // Looks like a back gesture would be welcome!
    return true;
  }

  static bool isGestureInProgress(PageRoute<dynamic> route) {
    return route.navigator!.userGestureInProgress;
  }
}

enum SwipeGestureType {
  swipeFromStart,
  swipeFromEnd,
}

class SwipeGestureDetector<T> extends StatefulWidget {
  const SwipeGestureDetector({
    super.key,
    required this.enabledCallback,
    required this.onStartGesture,
    required this.child,
  });

  final Widget child;

  final bool Function(SwipeGestureType) enabledCallback;

  final SwipeGestureController<T> Function(SwipeGestureType) onStartGesture;

  @override
  State<SwipeGestureDetector<T>> createState() =>
      _SwipeGestureDetectorState<T>();
}

class _SwipeGestureDetectorState<T> extends State<SwipeGestureDetector<T>> {
  SwipeGestureController<T>? _gestureController;

  late HorizontalDragGestureRecognizer _recognizer;
  SwipeGestureType type = SwipeGestureType.swipeFromStart;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();

    // If this is disposed during a drag, call navigator.didStopUserGesture.
    if (_gestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_gestureController?.navigator()?.mounted ?? false) {
          _gestureController?.navigator()?.didStopUserGesture();
        }
        _gestureController = null;
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_gestureController == null);
    _gestureController = widget.onStartGesture(type);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_gestureController != null);
    _gestureController!.dragUpdate(
        _convertToLogical(details.primaryDelta! / context.size!.width));
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_gestureController != null);
    _gestureController!.dragEnd(_convertToLogical(
        details.velocity.pixelsPerSecond.dx / context.size!.width));
    _gestureController = null;
  }

  void _handleDragCancel() {
    assert(mounted);
    // This can be called even if start is not called, paired with the "down" event
    // that we don't consider here.
    _gestureController?.dragEnd(0.0);
    _gestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback(type)) {
      type = SwipeGestureType.swipeFromStart;
      _recognizer.addPointer(event);
    }
  }

  void _handleEndAreaDown(PointerDownEvent event) {
    if (widget.enabledCallback(type)) {
      type = SwipeGestureType.swipeFromEnd;
      _recognizer.addPointer(event);
    }
  }

  double _convertToLogical(double value) {
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        return -value;
      case TextDirection.ltr:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    double dragAreaWidth = Directionality.of(context) == TextDirection.ltr
        ? MediaQuery.paddingOf(context).left
        : MediaQuery.paddingOf(context).right;
    dragAreaWidth = max(dragAreaWidth, _kGestureWidth);
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          start: 0.0,
          width: dragAreaWidth,
          top: 0.0,
          bottom: 0.0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        PositionedDirectional(
          end: 0.0,
          width: dragAreaWidth,
          top: 0.0,
          bottom: 0.0,
          child: Listener(
            onPointerDown: _handleEndAreaDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

class SwipeGestureController<T> {
  SwipeGestureController({
    required this.navigator,
    required this.controller,
  }) {
    navigator()?.didStartUserGesture();
  }

  final ValueGetter<AnimationController?> controller;
  final ValueGetter<NavigatorState?> navigator;

  /// The drag gesture has changed by [fractionalDelta]. The total range of the
  /// drag should be 0.0 to 1.0.
  void dragUpdate(double delta) {
    controller()?.value -= delta;
  }

  /// The drag gesture has ended with a horizontal motion of
  /// [fractionalVelocity] as a fraction of screen width per second.
  void dragEnd(double velocity) {
    final currentController = controller();
    if (currentController == null) return;

    // Fling in the appropriate direction.
    //
    // This curve has been determined through rigorously eyeballing native iOS
    // animations.
    const Curve animationCurve = Curves.fastLinearToSlowEaseIn;
    final bool animateForward;

    // If the user releases the page before mid screen with sufficient velocity,
    // or after mid screen, we should animate the page out. Otherwise, the page
    // should be animated back in.
    if (velocity.abs() >= _kMinFlingVelocity) {
      animateForward = velocity <= 0;
    } else {
      animateForward = currentController.value > 0.5;
    }

    if (animateForward) {
      // The closer the panel is to dismissing, the shorter the animation is.
      // We want to cap the animation time, but we want to use a linear curve
      // to determine it.
      final int droppedPageForwardAnimationTime = min(
        lerpDouble(_kMaxDroppedSwipePageForwardAnimationTime, 0,
                currentController.value)!
            .floor(),
        _kMaxPageBackAnimationTime,
      );
      currentController.animateTo(1.0,
          duration: Duration(milliseconds: droppedPageForwardAnimationTime),
          curve: animationCurve);
    } else {
      // This route is destined to pop at this point. Reuse navigator's pop.
      navigator()?.pop();

      // The popping may have finished inline if already at the target destination.
      if (currentController.isAnimating) {
        // Otherwise, use a custom popping animation duration and curve.
        final int droppedPageBackAnimationTime = lerpDouble(
                0,
                _kMaxDroppedSwipePageForwardAnimationTime,
                currentController.value)!
            .floor();
        currentController.animateBack(0.0,
            duration: Duration(milliseconds: droppedPageBackAnimationTime),
            curve: animationCurve);
      }
    }

    if (currentController.isAnimating) {
      // Keep the userGestureInProgress in true state so we don't change the
      // curve of the page transition mid-flight since CupertinoPageTransition
      // depends on userGestureInProgress.
      late AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        navigator()?.didStopUserGesture();
        controller()?.removeStatusListener(animationStatusCallback);
      };
      currentController.addStatusListener(animationStatusCallback);
    } else {
      navigator()?.didStopUserGesture();
    }
  }
}
