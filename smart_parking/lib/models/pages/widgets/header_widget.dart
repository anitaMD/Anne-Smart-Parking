// This widget will draw header section of all page. Wich you will get with the project source code.

import 'package:flutter/material.dart';

// ignore: must_be_immutable
class HeaderWidget extends StatefulWidget {
  final double height;
  final bool showIcon;
  final IconData icon;
  bool fromScanner = false;

  HeaderWidget({
    Key? key,
    required this.height,
    required this.showIcon,
    required this.icon,
    this.fromScanner = false,
  }) : super(key: key);

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  @override
  Widget build(BuildContext context) {
    double height = widget.height;
    bool showIcon = widget.showIcon;
    IconData icon = widget.icon;
    double width = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        ClipPath(
          clipper: ShapeClipper([
            Offset(width / 5, height),
            Offset(width / 10 * 5, height - 60),
            Offset(width / 5 * 4, height + 20),
            Offset(width, height - 18)
          ]),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    widget.fromScanner == false
                        ? Theme.of(context).primaryColor.withOpacity(0.4)
                        : Colors.grey.shade900,
                    widget.fromScanner == false
                        ? Theme.of(context).colorScheme.secondary.withOpacity(0.4)
                        : Colors.grey.shade800, //this one do not touch
                  ],
                  begin: const FractionalOffset(0.0, 0.0),
                  end: const FractionalOffset(1.0, 0.0),
                  stops: const [0.0, 1.0],
                  tileMode: TileMode.clamp),
            ),
          ),
        ),
        ClipPath(
          clipper: ShapeClipper([
            Offset(width / 3, height + 20),
            Offset(width / 10 * 8, height - 60),
            Offset(width / 5 * 4, height - 60),
            Offset(width, height - 20)
          ]),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    widget.fromScanner == false ? Theme.of(context).primaryColor.withOpacity(0.4) : Colors.brown,
                    widget.fromScanner == false
                        ? Theme.of(context).colorScheme.secondary.withOpacity(0.4)
                        : Colors.grey.shade700,
                  ],
                  begin: const FractionalOffset(0.0, 0.0),
                  end: const FractionalOffset(1.0, 0.0),
                  stops: const [0.0, 1.0],
                  tileMode: TileMode.clamp),
            ),
          ),
        ),
        ClipPath(
          clipper: ShapeClipper([
            Offset(width / 5, height),
            Offset(width / 2, height - 40),
            Offset(width / 5 * 4, height - 80),
            Offset(width, height - 20)
          ]),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    widget.fromScanner == false ? Theme.of(context).primaryColor : Colors.grey.shade900,
                    widget.fromScanner == false
                        ? Theme.of(context).colorScheme.secondary
                        : widget.fromScanner == false
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade900,
                  ],
                  begin: const FractionalOffset(0.0, 0.0),
                  end: const FractionalOffset(1.0, 0.0),
                  stops: const [0.0, 1.0],
                  tileMode: TileMode.clamp),
            ),
          ),
        ),
        widget.fromScanner
            ? Container(
                margin: const EdgeInsets.fromLTRB(25, 50, 25, 10),
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Icon(widget.icon,
                    size: 30,
                    color: Colors.white,
                    shadows: const [Shadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 5.0)]),
              )
            : Visibility(
                visible: showIcon,
                child: SizedBox(
                  height: height - 40,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.only(
                        left: 5.0,
                        top: 20.0,
                        right: 5.0,
                        bottom: 20.0,
                      ),
                      decoration: BoxDecoration(
                        // borderRadius: BorderRadius.circular(20),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(100),
                          topRight: Radius.circular(100),
                          bottomLeft: Radius.circular(60),
                          bottomRight: Radius.circular(60),
                        ),
                        border: Border.all(width: 5, color: Colors.white),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 40.0,
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class ShapeClipper extends CustomClipper<Path> {
  List<Offset> offsets = [];
  ShapeClipper(this.offsets);
  @override
  Path getClip(Size size) {
    var path = Path();

    path.lineTo(0.0, size.height - 20);

    // path.quadraticBezierTo(size.width/5, size.height, size.width/2, size.height-40);
    // path.quadraticBezierTo(size.width/5*4, size.height-80, size.width, size.height-20);

    path.quadraticBezierTo(offsets[0].dx, offsets[0].dy, offsets[1].dx, offsets[1].dy);
    path.quadraticBezierTo(offsets[2].dx, offsets[2].dy, offsets[3].dx, offsets[3].dy);

    // path.lineTo(size.width, size.height-20);
    path.lineTo(size.width, 0.0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
