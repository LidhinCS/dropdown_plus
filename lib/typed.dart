/// Opt-in typed generic API for [dropdown_plus_bloc].
///
/// Import separately from the main library:
///
/// ```dart
/// import 'package:dropdown_plus_bloc/typed.dart';
/// ```
///
/// Legacy [DropdownItem]-based widgets remain on:
///
/// ```dart
/// import 'package:dropdown_plus_bloc/dropdown_plus_bloc.dart';
/// ```
library dropdown_plus_typed;

export 'src/internal/dropdown_states.dart'
    show DropdownEmptyBuilder, DropdownErrorBuilder, DropdownLoadingBuilder;
export 'src/models/dropdown_plus_theme.dart';
export 'src/models/dropdown_plus_theme_style.dart';
export 'src/typed/dropdown_plus_controller.dart'
    show DropdownPlusController, DropdownPlusMultiController;
export 'src/typed/typed_dropdown_adapter.dart';
export 'src/typed/typed_dropdown_extensions.dart';
export 'src/typed/typed_multi_select_dropdown.dart';
export 'src/typed/typed_multi_select_dropdown_plus.dart';
export 'src/typed/typed_searchable_dropdown.dart';
export 'src/typed/typed_searchable_dropdown_plus.dart';
