# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.6] - 2026-03-15

### Added
- `SearchableDropdown` — single-select searchable dropdown without BLoC; pass `items`, `isLoading`, and optional `onSearch`.
- `MultiSelectDropdown` — multi-select with chips without BLoC; same pattern as `SearchableDropdown`.

### Docs
- README: widget overview, quick-start examples, and API tables for the non-BLoC dropdowns.

## [0.1.5] - 2026-03-15

### Docs
- Version bump and documentation-only update (no functional changes).

## [0.1.4] - 2026-03-15

### Docs
- Updated README with screenshots for better usage understanding.

## [0.1.3] - 2026-03-15

### Fixed
- Fixed `flutter_bloc` downgrade/analysis compatibility by removing the `StateStreamableSource` type constraint from dropdown widgets.

## [0.1.2] - 2026-03-15

### Added
- Added `DropdownPlusThemeStyle` preset enum (`material`, `minimal`, `rounded`, `outlined`, `dark`, `compact`) for out-of-the-box themed dropdown UIs
- Added `DropdownPlusThemePresets.forStyle(...)` helper to resolve preset themes programmatically
- Added `themeStyle` parameter to both `SearchableDropdownPlus` and `MultiSelectDropdownPlus`
- Exported `dropdown_plus_theme_style.dart` from the package entry library
- Updated README with preset theme style usage and API docs

### Fixed
- Fixed compact-mode bottom overflow in `MultiSelectDropdownPlus` by constraining open panel height to available parent space

## [0.1.0] - 2025-01-01

### Added
- Initial release
- `SearchableDropdownPlus` — single-select searchable dropdown with BLoC integration
- `MultiSelectDropdownPlus` — multi-select dropdown with chip display and BLoC integration
- `DropdownPlusTheme` — full visual customisation for all widget properties
- `DropdownItem<T>` — generic model for dropdown items
- Plain `StatefulWidget` implementation — no `flutter_hooks` dependency
- Offline caching with client-side fallback filtering
- Controlled-mode support via `selectedValue` / `selectedItems` props
- Animated open/close transitions and arrow rotation
- "Select All" / "Clear All" multi-select header
- Overflow chip badge (`+N more`) for multi-select trigger
- Custom `itemBuilder`, `selectedValueBuilder`, `selectedItemBuilder` hooks
- `checkInternetConnection` callback for custom connectivity detection
