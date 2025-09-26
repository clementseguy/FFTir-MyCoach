import 'package:flutter/material.dart';
class SeriesFormControllers {
  final TextEditingController shotCountController;
  final TextEditingController distanceController;
  final TextEditingController pointsController;
  final TextEditingController groupSizeController;
  final TextEditingController commentController;
  // FocusNodes pour gestion précise du focus
  final FocusNode shotCountFocus;
  final FocusNode distanceFocus;
  final FocusNode pointsFocus;
  final FocusNode groupSizeFocus;
  final FocusNode commentFocus;

  SeriesFormControllers({
    required int shotCount,
    required double distance,
    required int points,
    required double groupSize,
    required String comment,
  })  : shotCountController = TextEditingController(text: shotCount.toString()),
        distanceController = TextEditingController(text: distance.toString()),
        pointsController = TextEditingController(text: points.toString()),
        groupSizeController = TextEditingController(text: groupSize == 0 ? '0' : groupSize.toString()),
        commentController = TextEditingController(text: comment),
        shotCountFocus = FocusNode(),
        distanceFocus = FocusNode(),
        pointsFocus = FocusNode(),
        groupSizeFocus = FocusNode(),
        commentFocus = FocusNode();

  void dispose() {
    shotCountController.dispose();
    distanceController.dispose();
    pointsController.dispose();
    groupSizeController.dispose();
    commentController.dispose();
    shotCountFocus.dispose();
    distanceFocus.dispose();
    pointsFocus.dispose();
    groupSizeFocus.dispose();
    commentFocus.dispose();
  }
}
