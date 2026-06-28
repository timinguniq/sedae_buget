import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/theme/component/donut/category_donut.dart';

void main() {
  test('donutSweeps splits 2 equal values into half circles', () {
    final sweeps = donutSweeps([10, 10]);
    expect(sweeps.length, 2);
    expect(sweeps[0], closeTo(3.14159, 0.001)); // π
    expect(sweeps[1], closeTo(3.14159, 0.001));
  });
  test('empty/zero total yields empty sweeps', () {
    expect(donutSweeps([]), isEmpty);
    expect(donutSweeps([0, 0]), isEmpty);
  });
}
