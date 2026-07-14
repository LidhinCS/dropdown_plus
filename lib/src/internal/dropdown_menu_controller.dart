import 'package:flutter/foundation.dart';

/// Implemented by dropdown [State] so a [DropdownMenuController] can open/close
/// the panel. Not intended for application code.
abstract class DropdownMenuClient {
  /// Whether the dropdown panel is currently open.
  bool get isMenuOpen;

  /// Opens the panel (no-op if already open or disabled).
  Future<void> openMenu();

  /// Closes the panel (no-op if already closed).
  void closeMenu();
}

/// Base controller for programmatic open/close of a dropdown panel.
///
/// Extended by typed selection controllers; legacy widgets attach via
/// [attach] / [detach].
class DropdownMenuController extends ChangeNotifier {
  DropdownMenuClient? _client;

  /// Whether the attached dropdown panel is open.
  bool get isOpen => _client?.isMenuOpen ?? false;

  /// Whether a dropdown [State] is currently attached.
  bool get isAttached => _client != null;

  /// Called by dropdown [State] in [State.initState] / [State.didUpdateWidget].
  @protected
  void attach(DropdownMenuClient client) {
    if (identical(_client, client)) return;
    _client = client;
  }

  /// Called by dropdown [State] in [State.dispose] / when the controller changes.
  @protected
  void detach(DropdownMenuClient client) {
    if (identical(_client, client)) {
      _client = null;
    }
  }

  /// Opens the attached dropdown panel.
  Future<void> open() async {
    await _client?.openMenu();
    notifyListeners();
  }

  /// Closes the attached dropdown panel.
  void close() {
    _client?.closeMenu();
    notifyListeners();
  }

  @override
  void dispose() {
    _client = null;
    super.dispose();
  }
}

/// Public attach helpers used by legacy widget [State] (same library tree).
extension DropdownMenuControllerBinding on DropdownMenuController {
  /// Attaches [client] from dropdown State.
  void bindClient(DropdownMenuClient client) => attach(client);

  /// Detaches [client] from dropdown State.
  void unbindClient(DropdownMenuClient client) => detach(client);
}
