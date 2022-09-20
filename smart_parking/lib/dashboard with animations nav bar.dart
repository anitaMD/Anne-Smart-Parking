// ignore_for_file: file_names

/* import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/booking.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/dashboard_home.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/history.dart';
import 'package:smart_parking/screens/inside_app/for_dashboard/notifs.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  Color inactiveColor = Colors.black;
  Color isIconSelected = Colors.orange;
  Color isNotIconSelected = Colors.white;
  late TabController tabController;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 4, vsync: this);
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1,
    );

    tabController.animation!.addListener(
      () {
        if (tabController.indexIsChanging /* || tabController.index == 0 */) {
          animationController.forward(from: -0.1);
          setState(() {});
        }

        if (!tabController.indexIsChanging /* || tabController.index == 0 */) {
          animationController.forward(from: -0.1);
          setState(() {});
        }

        final value = tabController.animation!.value.round();
        if (value != _currentIndex && mounted) {
          animationController.forward(from: 0);
          setState(() {
            _currentIndex = value;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  /* 
  THIS WORKS IF I DON'T WANT TRANSITION ANIMATION
  Widget getBody() {
    List<Widget> pages = [
      const DashboardHomePage(),
      const BookingPage(),
      const HistoryPage(),
      const NotifsPage()
    ];
    return 
    IndexedStack(
      index: _currentIndex,
      children: 
      pages,
    );
  } */

  _tabBarView() {
    /* tabController.animation!.addListener(
      () {
        if (tabController.indexIsChanging) {
          animationController.forward(from: 0.5);
          setState(() {});
        }

        final value = tabController.animation!.value.round();
        if (value != _currentIndex && mounted) {
          setState(() {
            _currentIndex = value;
          });
        }
      },
    ); */

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Curves.easeIn,
      )),
      child: [
        const DashboardHomePage(),
        const BookingPage(),
        const HistoryPage(),
        const NotifsPage()
      ][tabController.index],
    );

    /* Transform.rotate(
          angle: tabController.animation!.value * pi,
          child: [
            const DashboardHomePage(),
            const BookingPage(),
            const HistoryPage(),
            const NotifsPage()
          ][tabController.animation!.value.round()],
        ); */
  }

  Widget myList() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35.0),
        color: Colors.black,
      ),
      child: Row(
        children: [
          Flexible(
            child: TabBar(
              onTap: (value) {
                setState(() {
                  if (value == 0) {
                    _currentIndex = 0;
                  } else if (value == 1) {
                    _currentIndex = 1;
                  } else if (value == 2) {
                    _currentIndex = 2;
                  } else if (value == 3) {
                    _currentIndex = 3;
                  }
                });
              },
              controller: tabController,
              automaticIndicatorColorAdjustment: true,
              indicatorColor: isIconSelected,
              indicatorWeight: 2,
              indicatorPadding: const EdgeInsets.only(
                left: 50,
                right: 50,
              ),
              dragStartBehavior: DragStartBehavior.down,
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.home,
                    color:
                        _currentIndex == 0 ? isIconSelected : isNotIconSelected,
                  ),
                ),
                Tab(
                  icon: Icon(
                    Icons.location_on_outlined,
                    color:
                        _currentIndex == 1 ? isIconSelected : isNotIconSelected,
                  ),
                ),
                Tab(
                  icon: Icon(
                    Icons.history,
                    color:
                        _currentIndex == 2 ? isIconSelected : isNotIconSelected,
                  ),
                ),
                Tab(
                  icon: Icon(
                    Icons.settings,
                    color:
                        _currentIndex == 3 ? isIconSelected : isNotIconSelected,
                  ),
                ),
              ],
            ),
            fit: FlexFit.loose,
          )
        ],
      ),
    );
  }

  _buildBottomBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 20),
      width: double.infinity,
      height: 60,
      child: myList(),
    );
  }

  //
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: _currentIndex,
      child: Scaffold(
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            _tabBarView(),
            //getBody(), SHOULD CALL THIS INSTEAD OF TABBARVIEW IF I DON't want page transition animation
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }
}


/* Widget menuItem(int id, IconData icon, bool selected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            if (id == 0) {
              _currentIndex = 0;
            } else if (id == 1) {
              _currentIndex = 1;
            } else if (id == 2) {
              _currentIndex = 2;
            } else if (id == 3) {
              _currentIndex = 3;
            }
          });
        },
        child: Icon(
          icon,
          size: 25,
          color: selected ? Colors.blue : Colors.white,
        ),
      ),
    );
  } */


/*  menuItem(0, Icons.home, _currentIndex == 0 ? true : false),
                  menuItem(1, Icons.location_on_outlined,
                      _currentIndex == 1 ? true : false),
                  menuItem(2, Icons.history, _currentIndex == 2 ? true : false),
                  menuItem(
                      3, Icons.settings, _currentIndex == 3 ? true : false),
                ]), */

 /*  Widget getBody() {
    List<Widget> pages = [
      const DashboardHomePage(),
      const BookingPage(),
      const HistoryPage(),
      const NotifsPage()
    ];
    return IndexedStack(
      index: _currentIndex,
      children: pages,
    );
  } */

 */