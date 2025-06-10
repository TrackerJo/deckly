import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/fancy_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? customBackButton;

  final void Function(BuildContext context)? onBackButtonPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBackButtonPressed,
    this.actions,
    this.customBackButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 3,
            color: Colors.transparent, // We'll use a gradient overlay
          ),
        ),
      ),
      child: Stack(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            toolbarHeight: 100,
            title: FittedBox(
              fit: BoxFit.fitWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FancyWidget(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontFamily: 'Inknut Antiqua',
                        fontWeight: FontWeight.w400,
                        height: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading:
                showBackButton
                    ? customBackButton != null
                        ? customBackButton
                        : FancyWidget(
                          child: IconButton(
                            splashColor: Colors.transparent,
                            splashRadius: 25,
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                            ),
                            onPressed: () async {
                              SharedPrefs.hapticButtonPress();
                              onBackButtonPressed!(context);
                            },
                            color: Colors.white,
                          ),
                        )
                    : Container(),
            actions: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions ?? [],
              ),
            ],
          ),
          // Gradient bottom border
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [styling.primaryColor, styling.secondaryColor],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
