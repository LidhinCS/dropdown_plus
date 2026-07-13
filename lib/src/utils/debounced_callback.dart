import 'dart:async';

/// Runs [action] after [duration], cancelling any pending invocation.
class DebouncedCallback {
  DebouncedCallback({this.duration = Duration.zero});

  final Duration duration;
  Timer? _timer;

  void call(void Function() action) {
    _timer?.cancel();
    if (duration == Duration.zero) {
      action();
      return;
    }
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Approximate height of the search field + divider inside the dropdown panel.
const double dropdownSearchHeaderHeight = 76.0;

/// Computes max height for the scrollable item list inside a dropdown panel.
double dropdownListMaxHeight(double menuMaxHeight) =>
    (menuMaxHeight - dropdownSearchHeaderHeight).clamp(80.0, menuMaxHeight);
