# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
