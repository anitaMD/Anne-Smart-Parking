import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:smart_parking/screens/authenticate/login_register.dart';
import 'package:smart_parking/styling/styling.dart';

class SliderScreen extends StatefulWidget {
  const SliderScreen({super.key});

  @override
  SliderScreenState createState() => SliderScreenState();
}

class SliderScreenState extends State<SliderScreen> {
  List<ContentConfig> slides = [];

  @override
  void initState() {
    // ignore: todo
    // TODO: implement initState
    super.initState();
    slides.add(ContentConfig(
      title: "Ne cherchez plus à l'aveuglette!",
      description:
          "Trouvez le smart parking le plus proche de vous et vérifier en temps réel la disponibilité des places.",
      pathImage: "assets/images/location_time.jpg",
      backgroundColor: bgcSlide1,
    ));

    slides.add(
      ContentConfig(
        title: "Gain de temps et d'argent!",
        description:
            "Réservez à distance votre place de parking et gagnez du temps au quotidien.",
        pathImage: "assets/images/book_now.jpg",
        backgroundColor: bgcSlide2,
      ),
    );

    slides.add(
      ContentConfig(
        title: "Avec vous jusqu'au bout!",
        description:
            "Notre système de guidage assisté à la place sera votre nouvel allié au quotidien.",
        pathImage: "assets/images/assisted_parking.jpg",
        backgroundColor: bgcSlide3,
      ),
    );

    slides.add(
      ContentConfig(
        title: "Propriétaire de parking?",
        description:
            "Votre parking remplit les critères d'un parking intelligent? Venez intégrer notre réseau sans plus tarder!",
        pathImage: "assets/images/handshake.jpg",
        backgroundColor: bgcSlide4,
      ),
    );
  }

  List<Widget> customizedTabs() {
    List<Widget> tabs = [];
    for (int i = 0; i < slides.length; i++) {
      ContentConfig currentSlide = slides[i];
      // ignore: sized_box_for_whitespace
      tabs.add(Container(
        width: double.infinity,
        height: double.infinity,
        //color: currentSlide.backgroundColor,
        color: Colors.black,

        child: Container(
          color: currentSlide
              .backgroundColor, //I'll get color box and the rest will be black
          margin: const EdgeInsets.only(bottom: 130, top: 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
                child: Image.asset(
                  currentSlide.pathImage.toString(),
                  fit: BoxFit.fitHeight,
                  matchTextDirection: true,
                  height: 80,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Text(
                  currentSlide.title.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 15, left: 20, right: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                ),
                child: Text(
                  currentSlide.description.toString(),
                  style: descTextStyle,
                  maxLines: 4,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ));
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      indicatorConfig: const IndicatorConfig(
        colorIndicator: Colors.white,
        sizeIndicator: 8.0,
        typeIndicatorAnimation: TypeIndicatorAnimation.sizeTransition,
      ),
      renderSkipBtn: const Text("SKIP"),
      renderNextBtn: const Text(
        'NEXT',
        style: TextStyle(color: Colors.white),
      ),
      renderDoneBtn: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(),
        ),
        child: const Text(
          'DONE',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
      listCustomTabs: customizedTabs(),
      scrollPhysics: const BouncingScrollPhysics(),
      onDonePress: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginRegister())),
    );
  }
}
