/// **dropdown_plus** — A customizable Flutter dropdown package with BLoC integration.
///
/// This library provides two powerful dropdown widgets:
/// - [SearchableDropdownPlus]: A single-select searchable dropdown with BLoC support.
/// - [MultiSelectDropdownPlus]: A multi-select dropdown with BLoC support and chip display.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:dropdown_plus/dropdown_plus.dart';
/// ```
///
/// ### Single Select
/// ```dart
/// SearchableDropdownPlus<MyCubit, MyState>(
///   cubit: myCubit,
///   hintText: 'Search and select...',
///   onSearch: myCubit.search,
///   onStateChange: (state, updateList, updateLoading) {
///     if (state is MyLoadedState) {
///       updateList(state.items.map((e) => DropdownItem(value: e, label: e.name)).toList());
///       updateLoading(false);
///     } else if (state is MyLoadingState) {
///       updateLoading(true);
///     }
///   },
///   onSelectionChanged: (item) => print('Selected: ${item.label}'),
/// );
/// ```
///
/// ### Multi Select
/// ```dart
/// MultiSelectDropdownPlus<MyCubit, MyState>(
///   cubit: myCubit,
///   hintText: 'Select items...',
///   onSearch: myCubit.search,
///   onStateChange: (state, updateList, updateLoading) {
///     if (state is MyLoadedState) {
///       updateList(state.items.map((e) => DropdownItem(value: e, label: e.name)).toList());
///       updateLoading(false);
///     } else if (state is MyLoadingState) {
///       updateLoading(true);
///     }
///   },
///   onSelectionChanged: (items) => print('Selected: ${items.map((e) => e.label).join(', ')}'),
/// );
/// ```
// ignore_for_file: directives_ordering
library dropdown_plus;

export 'src/models/dropdown_item.dart';
export 'src/models/dropdown_plus_theme.dart';
export 'src/widgets/multi_select_dropdown_plus.dart';
export 'src/widgets/searchable_dropdown_plus.dart';
