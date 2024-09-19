import 'package:flutter/material.dart';

class MapsBookingProcess extends StatefulWidget {
  const MapsBookingProcess({Key? key}) : super(key: key);

  @override
  MapsBookingProcessState createState() => MapsBookingProcessState();
}

class MapsBookingProcessState extends State<MapsBookingProcess> {
  int _currentStep = 0;
  bool complete = false;
  StepperType stepperType = StepperType.horizontal;

  //VARIABLES --------------------END

  stepState(int step) {
    if (_currentStep > step) {
      return StepState.complete;
    } else {
      return StepState.editing;
    }
  }

  List<Step> getSteps() {
    List<Step> steps = [
      Step(
        title: const Text('Select Smart Parking'),
        content: const _SmartParkingSelection(),
        state: stepState(0),
        isActive: _currentStep == 0,
      ),
      Step(
        title: const Text('Select A Car'),
        content: const _CarSelection(),
        state: stepState(1),
        isActive: _currentStep == 1,
      ),
      Step(
        title: const Text('Select Time Slot'),
        content: const _TimeSlotSelection(),
        state: stepState(2),
        isActive: _currentStep == 2,
      ),
      Step(
        title: const Text('Booking Overview'),
        content: const _TimeSlotSelection(),
        state: stepState(3),
        //isActive: _currentStep == 3,
      )
    ];
    return steps;
  }

  switchStepperType() {
    setState(() {
      stepperType == StepperType.horizontal
          ? stepperType == StepperType.vertical
          : stepperType == StepperType.horizontal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stepper(
            physics: const ScrollPhysics(),
            controlsBuilder: (BuildContext context, ControlsDetails controls) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: <Widget>[
                    ElevatedButton(
                      onPressed: controls.onStepContinue,
                      child: const Text('NEXT'),
                    ),
                    if (_currentStep != 0)
                      TextButton(
                        onPressed: controls.onStepCancel,
                        child: const Text(
                          'BACK',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              );
            },
            type: StepperType.vertical,
            elevation: 3.0,
            steps: getSteps(),
            onStepTapped: (step) => setState(() => _currentStep = step),
            onStepContinue: () {
              setState(() {
                if (_currentStep < getSteps().length - 1) {
                  _currentStep += 1;
                } else {
                  _currentStep = 0;
                }
              });
            },
            onStepCancel: () {
              setState(() {
                if (_currentStep > 0) {
                  _currentStep -= 1;
                } else {
                  _currentStep = 0;
                }
              });
            },
            currentStep: _currentStep,
          ),
        )
      ],
    );
  }
/*   List<Slide> slides = [];

  @override
  void initState() {
    // ignore: todo
    super.initState();
    slides.add(
      Slide(
        title: "Ne cherchez plus à l'aveuglette!",
        description:
            "Trouvez le smart parking le plus proche de vous et vérifier en temps réel la disponibilité des places.",
        pathImage: "assets/images/location_time.jpg",
        //backgroundColor: bgcSlide1,
        backgroundColor: Colors.black,
      ),
    );

    slides.add(
      Slide(
        title: "Gain de temps et d'argent!",
        description:
            "Réservez à distance votre place de parking et gagnez du temps au quotidien.",
        pathImage: "assets/images/book_now.jpg",
        backgroundColor: bgcSlide2,
      ),
    );

    slides.add(
      Slide(
        title: "Avec vous jusqu'au bout!",
        description:
            "Notre système de guidage assisté à la place sera votre nouvel allié au quotidien.",
        pathImage: "assets/images/assisted_parking.jpg",
        backgroundColor: bgcSlide3,
      ),
    );

    slides.add(
      Slide(
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
      Slide currentSlide = slides[i];
      tabs.add(
        Container(
          color: currentSlide
              .backgroundColor, //I'll get color box and the rest will be black
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white),
                child: Image.asset(
                  currentSlide.pathImage.toString(),
                  fit: BoxFit.fitHeight,
                  matchTextDirection: true,
                  height: 20,
                ),
              ),
              Container(
                //margin: const EdgeInsets.only(top: 20),
                child: Text(
                  currentSlide.title.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ),
              Container(
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
      );
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      colorDot: Colors.white,
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
      sizeDot: 8.0,
      typeDotAnimation: dotSliderAnimation.SIZE_TRANSITION,
      listCustomTabs: customizedTabs(),
      scrollPhysics: const BouncingScrollPhysics(),
      onDonePress:
          () {} /* => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginRegister())) */
      ,
    );
  } */
}

class _SmartParkingSelection extends StatelessWidget {
  const _SmartParkingSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 18.0),
          child: TextFormField(
            decoration: const InputDecoration(
              labelText:
                  'Street ADD PADDING TO SHORTEN THE HORIZONTAL BAR LENGTH, ADD A SEARCH BUTTON MAYBE',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 18.0),
          child: TextFormField(
            decoration: const InputDecoration(
              labelText:
                  'City remove STREET and keep city . CONGIG PARKING INFO VIEW ( NMBR PLACES LIBRES ETCS)',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 18.0),
          child: TextFormField(
            decoration: const InputDecoration(
              labelText:
                  'Postcode TO REMOVE OR REPLACE WITH SOMETHING ELSE AND CONFIG THE PARKING LAYOUT VIEW',
            ),
          ),
        ),
      ],
    );
  }
}

class _CarSelection extends StatelessWidget {
  const _CarSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Card number',
          ),
        ),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Expiry date',
          ),
        ),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'CVV',
          ),
        ),
      ],
    );
  }
}

class _TimeSlotSelection extends StatelessWidget {
  const _TimeSlotSelection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Center(
            child: Text(
                'Select booking time (USE CAN USE A STEPPER ALSO HERE TO DEFINE THE TIME OR WHATEVER')),
      ],
    );
  }
}

class BookingOverview extends StatelessWidget {
  const BookingOverview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Center(child: Text('Thank you for your order!')),
      ],
    );
  }
}
