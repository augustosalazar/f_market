import 'package:get/get.dart';

/// El indice de la pestana visible. Es lo unico que la carcasa necesita
/// recordar; cada pestana tiene su propio view model.
class HomeViewModel extends GetxController {
  final tabIndex = 0.obs;

  void goTo(int index) => tabIndex.value = index;
}
