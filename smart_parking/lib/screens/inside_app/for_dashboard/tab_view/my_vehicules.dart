import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MyVehiculesTab extends StatefulWidget {
  const MyVehiculesTab({Key? key}) : super(key: key);

  @override
  State<MyVehiculesTab> createState() => _MyVehiculesTabState();
}

final List<String> imgList = [
  'assets/images/car3.jpg',
  'assets/images/car1.jpg',
  'assets/images/car2.jpg',
  'assets/images/car4.jpg',
  'assets/images/car6.jpg',
  'assets/images/car5.jpg',
];

class _MyVehiculesTabState extends State<MyVehiculesTab> {
  int current = 0;

  final List<Widget> imageSliders = imgList
      .map((item) => Container(
            margin: const EdgeInsets.all(5.0),
            child: Image.asset(item, fit: BoxFit.fitWidth, width: 350.0),
          ))
      .toList();
  final CarouselSliderController _controller = CarouselSliderController();
  //
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CarouselSlider.builder(
          carouselController: _controller,
          itemCount: imgList.length,
          itemBuilder:
              (BuildContext context, int itemIndex, int pageViewIndex) =>
                  imageSliders.elementAt(itemIndex),
          options: CarouselOptions(
            onPageChanged: (index, reason) {
              setState(() {
                current = index;
              });
            },
            height: 150,
            aspectRatio: 16 / 9,
            viewportFraction: 0.8,
            initialPage: 0,
            enableInfiniteScroll: true,
            reverse: false,
            enlargeCenterPage: true,
            scrollDirection: Axis.horizontal,
          ),
        ),
        //
        AnimatedSmoothIndicator(
          activeIndex: current,
          duration: const Duration(milliseconds: 400),
          count: imageSliders.length,
          effect: const WormEffect(
              type: WormType.normal,
              spacing: 5.0,
              radius: 20.0,
              dotWidth: 10.0,
              dotHeight: 10.0,
              paintStyle: PaintingStyle.stroke,
              strokeWidth: 1.5,
              dotColor: Colors.black,
              activeDotColor: Colors.indigo),
        ),
        const SizedBox(
          height: 30,
        ),
        carInfoCard(),
      ],
    );
  }
}

/* car info: model, color, plaque immatriculation, AND EDIT OPTION + ADD CAR option (OR JUST DISPLAY THE INFO and allow the changes in a section of the profile page) */

Card carInfoCard() {
  return Card(
    color: Colors.indigo,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    elevation: 5,
    shadowColor: Colors.indigo.withAlpha(30),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Colors.white, width: 0.5),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.white.withAlpha(70),
                blurRadius: 8.0,
                spreadRadius: 1.0,
                offset: const Offset(
                  0.0,
                  0.5,
                ),
              ),
            ],
            borderRadius: BorderRadius.circular(15),
            /* gradient: const LinearGradient(
              /*    begin: Alignment.centerLeft,
                end: Alignment.centerRight, */
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color.fromARGB(0, 33, 34, 36),
                Color.fromARGB(255, 144, 163, 187)
              ]), */
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    //CAR BRAND CONTAINER
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(15)),
                    width: 80,
                    child: const Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        child: Text(
                          "HONDA",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'OpenSans'),
                        ),
                      ),
                    ),
                  ),
                  //
                  const Flexible(
                    // CAR COUNTRY CONTAINER
                    child: Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        child: Text(
                          "SENEGAL",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'OpenSans'),
                        ),
                      ),
                    ),
                  ),
                  //
                  Container(
                    // CAR YEAR CONTAINER
                    margin: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(15)),
                    width: 80,
                    //color: Colors.black.withAlpha(30),
                    child: const Align(
                      alignment: Alignment.center,
                      child: FittedBox(
                        child: Text(
                          "2015",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'OpenSans'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              //
              const Center(
                child: Text("5UHG797",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'OpenSans')),
              ),
              const SizedBox(height: 10),
              const Center(
                //"Description:
                child: Text(
                  "Honda Accord Lx",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w200,
                      fontFamily: 'OpenSans'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    ),
  );
}


/* import 'package:flutter/material.dart';
import 'package:smart_parking/models/cars_detail_card.dart';
import 'package:smart_parking/styling/styling.dart';

class CarDetail extends StatelessWidget {
  final String title;
  final double price;
  final String color;
  final String gearbox;
  final String fuel;
  final String brand;
  final String path;

  CarDetail(
      {Key? key,
      required this.title,
      required this.price,
      required this.color,
      required this.gearbox,
      required this.fuel,
      required this.brand,
      required this.path})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: mainHeading),
        Text(
          brand,
          style: basicHeading,
        ),
        Hero(tag: title, child: Image.asset(path)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SpecificsCard(
              name: '12 Month',
              price: price * 12,
              name2: 'Dollars',
            ),
            SpecificsCard(
              name: '6 Month',
              price: price * 6,
              name2: 'Dollars',
            ),
            SpecificsCard(
              name: '1 Month',
              price: price * 1,
              name2: 'Dollars',
            )
          ],
        ),
        SizedBox(height: 20),
        Text(
          'SPECIFICATIONS',
          style: TextStyle(
              color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SpecificsCard(
              name: 'Color',
              name2: color,
            ),
            SpecificsCard(
              name: 'Gearbox',
              name2: gearbox,
            ),
            SpecificsCard(
              name: 'Fuel',
              name2: fuel,
            )
          ],
        ),
        SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: null,
          child: Text(
            'Book Now',
            style: TextStyle(fontSize: 20, color: Colors.white),
          ),
        )
      ],
    );
  }
}
 */