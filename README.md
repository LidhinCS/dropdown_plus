# dropdown_plus

[![pub package](https://img.shields.io/pub/v/dropdown_plus.svg)](https://pub.dev/packages/dropdown_plus)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A highly customisable Flutter dropdown package with first-class **BLoC / Cubit** integration. Provides two ready-to-use widgets:

| Widget | Description |
|--------|-------------|
| `SearchableDropdownPlus` | Single-select searchable dropdown |
| `MultiSelectDropdownPlus` | Multi-select dropdown with chip display |

---

## Features

- 🔌 **BLoC / Cubit integration** — pass any `Cubit` or `Bloc` and let the widget react to state changes automatically
- 🔍 **Real-time search** — calls your cubit's search method as the user types
- 📴 **Offline caching** — falls back to client-side filtering when no internet is available
- 🎨 **Full theme customisation** — every colour, size, border and text style is configurable via `DropdownPlusTheme`
- 🧩 **Custom builders** — override item rows, chip display, and the trigger button content
- 🔄 **Controlled mode** — sync selected value(s) from external state (e.g. QR scan, form reset)
- ✅ **Multi-select helpers** — "Select All" / "Clear All" header, "+N more" overflow chip
- 🎞 **Smooth animations** — animated open/close, arrow rotation, item selection

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dropdown_plus: ^0.1.0
  flutter_bloc: ">=8.0.0 <10.0.0"   # only transitive dep needed
```

Then run:

```bash
flutter pub get
```

---

## Quick Start

```dart
import 'package:dropdown_plus/dropdown_plus.dart';
```

### Single Select

```dart
SearchableDropdownPlus<WorkerCubit, WorkerState>(
  cubit: context.read<WorkerCubit>(),
  hintText: 'Search worker…',
  onSearch: (query) => context.read<WorkerCubit>().search(query),
  onStateChange: (state, updateList, updateLoading) {
    if (state is WorkersLoaded) {
      updateList(
        state.workers
            .map((w) => DropdownItem(value: w, label: w.name))
            .toList(),
      );
      updateLoading(false);
    } else if (state is WorkersLoading) {
      updateLoading(true);
    } else if (state is WorkersError) {
      updateLoading(false);
    }
  },
  onSelectionChanged: (item) {
    final worker = item.value as Worker;
    // use worker
  },
)
```

### Multi Select

```dart
MultiSelectDropdownPlus<WorkerCubit, WorkerState>(
  cubit: context.read<WorkerCubit>(),
  hintText: 'Select workers…',
  onSearch: (query) => context.read<WorkerCubit>().search(query),
  onStateChange: (state, updateList, updateLoading) {
    if (state is WorkersLoaded) {
      updateList(
        state.workers
            .map((w) => DropdownItem(value: w, label: '${w.name} (${w.id})'))
            .toList(),
      );
      updateLoading(false);
    } else if (state is WorkersLoading) {
      updateLoading(true);
    }
  },
  onSelectionChanged: (items) {
    final workers = items.map((e) => e.value as Worker).toList();
    // use workers
  },
)
```

---

## Theme Customisation

Pass a `DropdownPlusTheme` to either widget to change its appearance:

```dart
SearchableDropdownPlus(
  ...
  dropdownTheme: DropdownPlusTheme(
    // Trigger button
    backgroundColor: Colors.grey[100],
    borderColor: Colors.grey[300],
    activeBorderColor: Colors.deepPurple,
    borderRadius: 12,

    // Hint & text
    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
    triggerTextStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),

    // Dropdown panel
    menuBackgroundColor: Colors.white,
    menuBorderRadius: 16,
    menuElevation: 8,
    menuMaxHeight: 280,

    // Search bar
    searchBarBackgroundColor: Colors.grey[50],
    searchHintStyle: TextStyle(color: Colors.grey),
    searchIconColor: Colors.grey,

    // Items
    itemTextStyle: TextStyle(color: Colors.black87),
    selectedItemTextStyle: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
    selectedItemBackgroundColor: Colors.deepPurple.withOpacity(0.08),

    // Loading / empty
    loadingIndicatorColor: Colors.deepPurple,
    noResultsTextStyle: TextStyle(color: Colors.grey),
  ),
)
```

### Dark Theme Example

```dart
dropdownTheme: DropdownPlusTheme(
  backgroundColor: const Color(0xFF1E1E2E),
  menuBackgroundColor: const Color(0xFF2A2A3E),
  borderColor: Colors.white12,
  activeBorderColor: Colors.blueAccent,
  hintStyle: TextStyle(color: Colors.white38),
  triggerTextStyle: TextStyle(color: Colors.white),
  itemTextStyle: TextStyle(color: Colors.white70),
  selectedItemTextStyle: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
  selectedItemBackgroundColor: Colors.blueAccent.withOpacity(0.15),
  dividerColor: Colors.white10,
  searchBarBackgroundColor: Colors.white10,
  searchHintStyle: TextStyle(color: Colors.white38),
  searchTextStyle: TextStyle(color: Colors.white),
  searchIconColor: Colors.white38,
  chipBackgroundColor: Colors.blueAccent.withOpacity(0.2),
  chipTextStyle: TextStyle(color: Colors.blueAccent),
  chipBorderColor: Colors.blueAccent.withOpacity(0.4),
  loadingIndicatorColor: Colors.blueAccent,
  checkboxActiveColor: Colors.blueAccent,
  headerBackgroundColor: const Color(0xFF252535),
  arrowIconColor: Colors.white54,
)
```

---

## `DropdownPlusTheme` Reference

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `backgroundColor` | `Color?` | `Colors.white` | Trigger button background |
| `borderColor` | `Color?` | `outline@50%` | Border colour when closed |
| `activeBorderColor` | `Color?` | `primary` | Border colour when open |
| `borderWidth` | `double` | `1.0` | Border width when closed |
| `activeBorderWidth` | `double` | `1.5` | Border width when open |
| `borderRadius` | `double` | `10.0` | Trigger corner radius |
| `contentPadding` | `EdgeInsets?` | `h14 v12` | Trigger inner padding |
| `hintStyle` | `TextStyle?` | `onSurface@60%` | Placeholder text style |
| `triggerTextStyle` | `TextStyle?` | `bodyMedium` | Selected value text style (single) |
| `menuBackgroundColor` | `Color?` | `Colors.white` | Panel background |
| `menuBorderRadius` | `double` | `12.0` | Panel corner radius |
| `menuElevation` | `double` | `12.0` | Panel shadow elevation |
| `menuMaxHeight` | `double` | `320.0` | Panel max height |
| `menuBorderColor` | `Color?` | `outline@20%` | Panel border colour |
| `searchBarBackgroundColor` | `Color?` | `surface@30%` | Search input container |
| `searchHintStyle` | `TextStyle?` | `onSurface@50%` | Search hint |
| `searchTextStyle` | `TextStyle?` | theme default | Search input text |
| `searchIconColor` | `Color?` | `onSurface@50%` | Search icon |
| `itemTextStyle` | `TextStyle?` | `onSurface 14sp` | Normal item text |
| `selectedItemTextStyle` | `TextStyle?` | `primary w500` | Selected item text |
| `selectedItemBackgroundColor` | `Color?` | `primaryContainer@30%` | Selected item row bg |
| `itemPadding` | `EdgeInsets?` | `h16 v12` | Item row padding |
| `dividerColor` | `Color?` | `outline@8%` | Divider between items |
| `checkboxBorderColor` | `Color?` | `outline@40%` | Circle checkbox border (unselected) |
| `checkboxActiveColor` | `Color?` | `primary` | Circle checkbox fill (selected) |
| `checkboxSize` | `double` | `22.0` | Circle checkbox diameter |
| `chipBackgroundColor` | `Color?` | `primary@10%` | Chip background |
| `chipTextStyle` | `TextStyle?` | `primary w500 12sp` | Chip text |
| `chipBorderColor` | `Color?` | `primary@30%` | Chip border |
| `chipBorderRadius` | `double` | `16.0` | Chip corner radius |
| `chipDeleteIconColor` | `Color?` | `primary` | Chip × icon colour |
| `chipDeleteIconSize` | `double` | `14.0` | Chip × icon size |
| `countChipBackgroundColor` | `Color?` | `surfaceContainerHighest` | "+N more" chip background |
| `countChipTextStyle` | `TextStyle?` | `onSurface@70%` | "+N more" chip text |
| `loadingIndicatorColor` | `Color?` | `primary` | Spinner colour |
| `loadingTextStyle` | `TextStyle?` | `onSurface@60% 13sp` | Loading message style |
| `noResultsTextStyle` | `TextStyle?` | `onSurface@60% 13sp` | No results message style |
| `noResultsIconColor` | `Color?` | `onSurface@40%` | No results icon colour |
| `arrowIconColor` | `Color?` | `onSurface@60%` | Caret icon colour |
| `arrowIconSize` | `double` | `22.0` | Caret icon size |
| `headerBackgroundColor` | `Color?` | `surface@30%` | Multi-select header row bg |
| `selectAllTextStyle` | `TextStyle?` | `primary w600 13sp` | "Select All" button style |
| `selectedCountTextStyle` | `TextStyle?` | `primary w600 11sp` | "N selected" badge text |
| `selectedCountBackgroundColor` | `Color?` | `primary@10%` | "N selected" badge bg |

---

## API Reference

### `SearchableDropdownPlus<C, S>`

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `cubit` | `C` | ✅ | BLoC/Cubit instance |
| `onSearch` | `void Function(String)` | ✅ | Called on every search change |
| `onStateChange` | `void Function(S, updateList, updateLoading)` | ✅ | Maps state to list/loading updates |
| `hintText` | `String` | ✅ | Placeholder text |
| `selectedValue` | `DropdownItem?` | — | Pre-selected value (controlled mode) |
| `onSelectionChanged` | `void Function(DropdownItem)?` | — | User selection callback |
| `searchHint` | `String?` | — | Search input placeholder |
| `noResultsText` | `String?` | — | Empty-state message |
| `loadingText` | `String?` | — | Loading-state message |
| `needInitialFetch` | `bool` | — | Trigger search on mount (default: `false`) |
| `dropdownTheme` | `DropdownPlusTheme?` | — | Visual customisation |
| `itemBuilder` | `Widget Function(item, isSelected)?` | — | Custom item row |
| `selectedValueBuilder` | `Widget Function(item)?` | — | Custom trigger content |
| `checkInternetConnection` | `Future<bool> Function()?` | — | Custom connectivity check |

### `MultiSelectDropdownPlus<C, S>`

All parameters from `SearchableDropdownPlus` plus:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `selectedItems` | `List<DropdownItem>` | `[]` | Pre-selected items (controlled) |
| `onSelectionChanged` | `void Function(List<DropdownItem>)?` | — | Selection change callback |
| `maxDisplayChips` | `int` | `2` | Max chips before "+N more" overflow |
| `selectedItemBuilder` | `Widget Function(List<DropdownItem>)?` | — | Custom chips display |
| `buttonHeight` | `double?` | — | Fixed trigger height |
| `buttonWidth` | `double?` | — | Fixed trigger width |

---

## Offline Caching

Provide `checkInternetConnection` to enable offline fallback:

```dart
SearchableDropdownPlus(
  ...
  checkInternetConnection: () async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  },
)
```

When offline, the widget performs client-side filtering on the cached item list instead of calling `onSearch`.

---

## Controlled Mode

Use `selectedValue` / `selectedItems` to sync selection with external state (e.g. form reset, QR scan):

```dart
// For QR scan — increment key to force re-sync
SearchableDropdownPlus(
  key: ValueKey(qrKey),
  selectedValue: scannedItem,
  ...
)
```

---

## Custom Builders

### Custom item row

```dart
SearchableDropdownPlus(
  ...
  itemBuilder: (item, isSelected) {
    final worker = item.value as Worker;
    return ListTile(
      leading: CircleAvatar(child: Text(worker.name[0])),
      title: Text(worker.name),
      subtitle: Text(worker.department),
      trailing: isSelected ? Icon(Icons.check, color: Colors.green) : null,
    );
  },
)
```

### Custom selected chips (multi-select)

```dart
MultiSelectDropdownPlus(
  ...
  selectedItemBuilder: (selected) => Text(
    selected.map((e) => e.label).join(' • '),
    overflow: TextOverflow.ellipsis,
  ),
)
```

---

## License

MIT © LidhinCS
