import 'package:intl/intl.dart';

/// Formatos que se repiten en varias pantallas.
class Formatters {
  static final _price = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
  );
  static final _number = NumberFormat.decimalPattern('es_CO');
  static final _date = DateFormat('d MMM yyyy', 'es');

  static String price(double value) => _price.format(value);

  static String mileage(int km) => '${_number.format(km)} km';

  static String date(DateTime value) => _date.format(value);

  /// Antiguedad en palabras: «hace 3 h». Para listas y chats.
  static String relative(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 30) return 'hace ${diff.inDays} d';
    return date(value);
  }

  static String time(DateTime value) => DateFormat.Hm().format(value);
}
