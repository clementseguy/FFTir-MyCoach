import 'package:flutter/material.dart';
class SeriesFormControllers {
  final TextEditingController shotCountController;
  final TextEditingController distanceController;
  final TextEditingController pointsController;
  final TextEditingController groupSizeController;
  final TextEditingController commentController;

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
        commentController = TextEditingController(text: comment);

  void dispose() {
    shotCountController.dispose();
    distanceController.dispose();
    pointsController.dispose();
    groupSizeController.dispose();
    commentController.dispose();
  }
}
