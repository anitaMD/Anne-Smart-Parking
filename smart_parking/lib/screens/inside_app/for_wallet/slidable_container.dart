import 'package:flutter/cupertino.dart';

class SlidableWalletCard extends StatefulWidget {
  final Widget childLeft, childRight;
  final Function onSlided;
  const SlidableWalletCard(
      {super.key,
      required this.childLeft,
      required this.childRight,
      required this.onSlided});

  @override
  State<SlidableWalletCard> createState() => _SlidableWalletCardState();
}

class _SlidableWalletCardState extends State<SlidableWalletCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String swipeDirection = '';
  int currentIndex = 0;
  double dragExtent = 0, lastDragExtent = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "CONTROLLER DEBUG: ${_controller.value} ___ veloc ${_controller.velocity}");

    return GestureDetector(
        onHorizontalDragStart: ((details) {
          debugPrint(
              "CONTROLLER: ${_controller.value} ___ veloc ${_controller.velocity}");

          setState(() {
            _controller.reset();
            swipeDirection == 'next' ? _controller.fling(velocity: 0) : null;
            // _controller.fling(velocity: 0);
            dragExtent = 0;
            // currentIndex == 1 && swipeDirection == 'next' ? dragExtent = 1 : dragExtent = 0;
          });
        }),
        onHorizontalDragUpdate: (details) {
          dragExtent += details.primaryDelta!;
          debugPrint("EXTENT: $dragExtent");
          setState(() {
            //swipeDirection = details.delta.dx < 0 ? 'next' : 'prev';
            _controller.value =
                dragExtent / context.size!.width; //drageExtent.  abs()
          });
        },
        onHorizontalDragEnd: (details) {
          debugPrint("EXTENTEND: $dragExtent");
          if (dragExtent < 0) {
            currentIndex < 1
                ? setState(() {
                    swipeDirection = 'next';
                    currentIndex = 1;
                    widget.onSlided(currentIndex);
                  })
                : null;
            debugPrint(
                "SWIPE DIRECTION: $swipeDirection _ currentIndex $currentIndex");
          } else {
            currentIndex > 0
                ? setState(() {
                    swipeDirection = 'prev';
                    currentIndex = 0;
                    widget.onSlided(currentIndex);
                  })
                : null;

            debugPrint(
                "SWIPE DIRECTION: $swipeDirection _ _ currentIndex $currentIndex");
          }

          _controller.fling(velocity: -1);
        },
        child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return swipeDirection == 'next'
                  ? widget.childRight
                  : widget
                      .childLeft; /*  SlideTransition(
                  position: swipeDirection == 'next'
                      ? AlwaysStoppedAnimation(Offset(_controller.value, 0))
                      : swipeDirection == 'prev'
                          ? AlwaysStoppedAnimation(Offset(-_controller.value, 0))
                          : AlwaysStoppedAnimation(Offset(_controller.value, 0)),
                  child: swipeDirection == 'next' ? widget.childRight : widget.childLeft); */
            }));
  }
}
