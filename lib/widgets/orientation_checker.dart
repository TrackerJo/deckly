import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart';

class OrientationChecker extends StatefulWidget {
  final Widget child;
  final allowedOrientations;
  final Function(Orientation)? onOrientationChange;
  final bool isSolitaire;
  const OrientationChecker({
    super.key,
    required this.child,
    this.onOrientationChange,
    this.allowedOrientations = const [Orientation.portrait],
    this.isSolitaire = false,
  });

  @override
  State<OrientationChecker> createState() => _OrientationCheckerState();
}

class _OrientationCheckerState extends State<OrientationChecker> {
  bool seenSolitaire = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.isSolitaire) {
      SharedPrefs.getSeenSolitaire().then((value) {
        seenSolitaire = value;
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        // Check if the orientation is landscape
        if (widget.onOrientationChange != null) {
          widget.onOrientationChange!(orientation);
        }
        return Stack(
          children: [
            widget.child,

            if (orientation == Orientation.landscape &&
                !widget.allowedOrientations.contains(Orientation.landscape))
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SFIcon(
                        SFIcons.sf_rectangle_portrait_rotate,
                        color: Colors.white,
                        fontSize: 50,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Please rotate your device to portrait mode',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          decorationColor: Colors.black.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            if (orientation == Orientation.portrait &&
                !widget.allowedOrientations.contains(Orientation.portrait))
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SFIcon(
                        SFIcons.sf_rectangle_landscape_rotate,
                        color: Colors.white,
                        fontSize: 50,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Please rotate your device to landscape mode',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          decorationColor: Colors.black.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.isSolitaire &&
                !seenSolitaire &&
                orientation == Orientation.portrait)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SFIcon(
                        SFIcons.sf_rectangle_landscape_rotate,
                        color: Colors.white,
                        fontSize: 50,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Welcome to Solitaire!\nPlease rotate your device to landscape mode for the best experience.\nYou can also play in portrait mode, but landscape is recommended.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decorationColor: Colors.black.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ActionButton(
                        width: 100,
                        text: Text(
                          "Okay",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        onTap: () {
                          seenSolitaire = true;
                          setState(() {});
                          print("Seen Solitaire: $seenSolitaire");

                          SharedPrefs.setSeenSolitaire(true);
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
