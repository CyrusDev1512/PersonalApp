import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:personal_finance/utils/currency.dart';
import 'package:personal_finance/utils/dates.dart';

TextEditingValue _type(String text, {int? cursor}) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi_VN');
  });

  group('formatVnd', () {
    test('dấu chấm ngăn cách hàng nghìn + đ', () {
      expect(formatVnd(6500000), '6.500.000đ');
      expect(formatVnd(500000), '500.000đ');
      expect(formatVnd(1000), '1.000đ');
      expect(formatVnd(999), '999đ');
      expect(formatVnd(0), '0đ');
      expect(formatVnd(-500000), '-500.000đ');
      expect(formatVnd(100000000000), '100.000.000.000đ');
    });

    test('có dấu theo chiều và gạch ngang khi chưa biết', () {
      expect(formatSignedVnd(3500000, outgoing: true), '−3.500.000đ');
      expect(formatSignedVnd(3500000, outgoing: false), '+3.500.000đ');
      expect(formatVndOrDash(null), '—');
      expect(formatVndOrDash(1500), '1.500đ');
    });
  });

  group('parseVnd', () {
    test('đọc lại số đã định dạng', () {
      expect(parseVnd('6.500.000đ'), 6500000);
      expect(parseVnd('6.500.000'), 6500000);
      expect(parseVnd('6500000'), 6500000);
      expect(parseVnd(' 1.000.000,00 '), 1000000);
      expect(parseVnd('1,000,000'), 1000000);
      expect(parseVnd('-500.000đ'), -500000);
      expect(parseVnd('0'), 0);
    });

    test('rỗng hoặc không có chữ số -> null', () {
      expect(parseVnd(''), isNull);
      expect(parseVnd('   '), isNull);
      expect(parseVnd('abc'), isNull);
      expect(parseVnd(null), isNull);
    });

    test('format rồi parse giữ nguyên giá trị', () {
      for (final v in [0, 7, 1234, 6500000, 123456789012]) {
        expect(parseVnd(formatVnd(v)), v);
      }
    });
  });

  group('VndInputFormatter', () {
    const f = VndInputFormatter();

    test('định dạng khi gõ, con trỏ ở cuối', () {
      final out = f.formatEditUpdate(_type('123456'), _type('1234567'));
      expect(out.text, '1.234.567');
      expect(out.selection.baseOffset, out.text.length);
    });

    test('bỏ ký tự không phải số và số 0 ở đầu', () {
      expect(f.formatEditUpdate(_type(''), _type('00a5b0c0')).text, '500');
      expect(f.formatEditUpdate(_type(''), _type('0')).text, '0');
    });

    test('xoá hết -> rỗng', () {
      final out = f.formatEditUpdate(_type('5'), _type(''));
      expect(out.text, '');
      expect(out.selection.baseOffset, 0);
    });

    test('xoá một chữ số ở giữa: định dạng lại và giữ vị trí con trỏ', () {
      // "1.234.567" xoá "4" (con trỏ sau "3") -> "1.23.567"
      final out = f.formatEditUpdate(_type('1.234.567'), _type('1.23.567', cursor: 4));
      expect(out.text, '123.567');
      // Sau con trỏ vẫn là 3 chữ số "567".
      expect(out.text.substring(out.selection.baseOffset).replaceAll('.', ''), '567');
    });

    test('backspace ngay sau dấu chấm: xoá luôn chữ số đứng trước', () {
      // "123.|456" → hệ thống chỉ xoá "." → "123|456".
      final out = f.formatEditUpdate(_type('123.456', cursor: 4), _type('123456', cursor: 3));
      expect(out.text, '12.456');
      expect(out.selection.baseOffset, 3); // "12.|456"
    });

    test('giữ backspace giữa số: mỗi lần xoá một chữ số, không bị kẹt ở dấu chấm', () {
      // "1.234|.567" → "123.|567" → "12.|567" → "1.|567".
      var value = _type('1.234.567', cursor: 5);
      final texts = <String>[];
      for (var i = 0; i < 3; i++) {
        final cursor = value.selection.baseOffset;
        final edited = value.text.substring(0, cursor - 1) + value.text.substring(cursor);
        value = f.formatEditUpdate(value, _type(edited, cursor: cursor - 1));
        texts.add(value.text);
      }
      expect(texts, ['123.567', '12.567', '1.567']);
      expect(value.text.substring(value.selection.baseOffset).replaceAll('.', ''), '567');
    });

    test('phím xoá tới (delete) ngay trước dấu chấm: xoá chữ số đứng sau', () {
      // "123|.456" → hệ thống chỉ xoá "." → "123|456".
      final out = f.formatEditUpdate(_type('123.456', cursor: 3), _type('123456', cursor: 3));
      expect(out.text, '12.356');
      expect(out.text.substring(out.selection.baseOffset).replaceAll('.', ''), '56');
    });

    test('quá dài thì giữ giá trị cũ', () {
      final old = _type('1.234.567.890.123');
      final out = f.formatEditUpdate(old, _type('1.234.567.890.1234'));
      expect(out.text, old.text);
    });
  });

  group('dates', () {
    test('tháng hiện tại theo giờ Việt Nam', () {
      // 18:00 UTC ngày 31/10 = 01:00 ngày 1/11 giờ VN.
      expect(currentMonthIct(DateTime.utc(2026, 10, 31, 18)), '2026-11');
      expect(currentMonthIct(DateTime.utc(2026, 10, 31, 16, 59)), '2026-10');
      expect(monthOfIct(DateTime.utc(2026, 9, 30, 17)), '2026-10');
    });

    test('cộng trừ tháng và nhãn', () {
      expect(shiftMonth('2026-12', 1), '2027-01');
      expect(shiftMonth('2026-01', -1), '2025-12');
      expect(shiftMonth('2026-10', 0), '2026-10');
      expect(monthLabel('2026-10'), 'Tháng 10/2026');
      expect(parseMonth('2026-13'), isNull);
    });
  });
}
