String formatNumber(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

const _weekdays = ['Даваа', 'Мягмар', 'Лхагва', 'Пүрэв', 'Баасан', 'Бямба', 'Ням'];

String weekdayName(DateTime d) => _weekdays[d.weekday - 1];

/// "09.24"
String shortDate(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

/// "2026.09.24, Лхагва"
String longDate(DateTime d) => '${d.year}.${shortDate(d)}, ${weekdayName(d)}';
