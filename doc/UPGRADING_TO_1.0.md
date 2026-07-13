# Upgrading to 1.0

## Summary

**Version 1.0 is backward compatible.** Existing `SearchableDropdownPlus`, `MultiSelectDropdownPlus`, `SearchableDropdown`, and `MultiSelectDropdown` call sites should work without code changes.

Update `pubspec.yaml`:

```yaml
dependencies:
  dropdown_plus_bloc: ^1.0.0
```

## What changed

### Bug fixes

- **Cubit lifecycle** — `*Plus` widgets no longer close a parent-owned cubit when the dropdown is removed from the tree. They now use `BlocProvider.value`.
- **Single-select list height** — item lists respect `DropdownPlusTheme.menuMaxHeight` instead of a hardcoded 200px cap.

### Additive API

- **`debounceDuration`** — optional on all four widgets (default `Duration.zero`, preserving current behaviour).

### Documentation

- README import paths use `dropdown_plus_bloc`.
- Example app disposes cubits correctly.

## Optional: enable debounced search

```dart
SearchableDropdownPlus<UsersCubit, UsersState>(
  cubit: cubit,
  debounceDuration: const Duration(milliseconds: 400),
  // ...
)
```

## No migration required for

- `onStateChange` / `onSearch` / `DropdownItem` patterns
- `themeStyle` / `dropdownTheme`
- Controlled mode (`selectedValue` / `selectedItems`)
- Non-BLoC widgets
