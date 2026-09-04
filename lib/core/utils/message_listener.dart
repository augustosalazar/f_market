import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Conecta los avisos que publica un view model con la barra inferior de la
/// pantalla.
///
/// Los view models no tocan widgets: escriben en un `RxnString` y quien lo
/// pinta es la vista. Asi el view model se puede probar sin Flutter, que era
/// justo lo que impedia el `Get.snackbar` metido dentro del controlador.
mixin MessageListener<T extends StatefulWidget> on State<T> {
  final _workers = <Worker>[];

  /// Empieza a escuchar. Llamalo una vez, en `initState`.
  void listenMessages({RxnString? message, RxnString? error}) {
    if (message != null) _listen(message, isError: false);
    if (error != null) _listen(error, isError: true);
  }

  void _listen(RxnString source, {required bool isError}) {
    _workers.add(
      ever(source, (String? text) {
        if (text == null || !mounted) return;
        final scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(text),
              backgroundColor: isError ? scheme.errorContainer : null,
              behavior: SnackBarBehavior.floating,
            ),
          );
        source.value = null;
      }),
    );
  }

  @override
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    super.dispose();
  }
}
