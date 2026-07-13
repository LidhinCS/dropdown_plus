import 'package:dropdown_plus_bloc/src/utils/debounced_callback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('runs immediately when duration is zero', () {
    var count = 0;
    final debounced = DebouncedCallback();
    debounced(() => count++);
    expect(count, 1);
    debounced.dispose();
  });

  test('debounces invocations', () async {
    var count = 0;
    final debounced = DebouncedCallback(
      duration: const Duration(milliseconds: 50),
    );
    debounced(() => count++);
    debounced(() => count++);
    debounced(() => count++);
    expect(count, 0);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(count, 1);
    debounced.dispose();
  });
}
