# Post-1.0 Roadmap

This document outlines planned work after **1.0.0** (published on pub.dev): an **additive typed/generic API** and **production enhancements**, without breaking existing consumers.

See also: [UPGRADING_TO_1.0.md](UPGRADING_TO_1.0.md) for the stable 1.0 baseline.

---

## Goals

1. **Typed generic API** — work with `User` directly instead of `DropdownItem` + casts; BLoC remains central.
2. **Production enhancements** — error UI, form fields, custom builders, scale, accessibility.
3. **Zero breakage** — `1.0.0` API stays the default export; no breaking changes in minor releases.
4. **One internal UI layer** — stop maintaining four near-duplicate widget implementations.

---

## Guiding principles

| Rule | Detail |
|------|--------|
| Default export | `package:dropdown_plus_bloc/dropdown_plus_bloc.dart` = **1.0 API only** |
| Opt-in typed API | `package:dropdown_plus_bloc/typed.dart` (name TBD before implementation) |
| Legacy widgets | Current `*Plus` and non-BLoC widgets **not** deprecated until typed API is proven (earliest **2.0**) |
| BLoC | Typed `*Plus` keeps `<C, S>`; only the **data** side is simplified |
| Semver | **1.1** = enhancements; **1.2** = typed preview; **2.0** = deprecations only if justified |

---

## Current baseline (1.0.0)

**Main export** (`lib/dropdown_plus_bloc.dart`):

- `SearchableDropdownPlus<C, S>`
- `MultiSelectDropdownPlus<C, S>`
- `SearchableDropdown` (item-based, `items` + `isLoading`)
- `MultiSelectDropdown`
- `DropdownItem<T>`, `DropdownPlusTheme`, presets

**Already shipped in 1.0:**

- Cubit lifecycle fix (`BlocProvider.value`)
- `debounceDuration` on all four widgets
- `dropdownListMaxHeight()` for theme-aware list height
- Widget tests, example fixes, `UPGRADING_TO_1.0.md`

---

## Phase 0 — Foundation

**Target version:** `1.1.0`  
**Risk:** Low — internal refactor + additive parameters only

### 0.1 Extract shared UI (private)

```
lib/src/internal/
  dropdown_theme_resolver.dart      # themeStyle + dropdownTheme → DropdownPlusTheme
  dropdown_panel.dart               # Material panel, search bar, divider
  dropdown_trigger.dart             # single + multi trigger shell
  dropdown_item_list.dart            # list rendering (later ListView.builder)
  dropdown_empty_state.dart
  dropdown_loading_state.dart
```

Existing utilities stay under `lib/src/utils/` (`debounced_callback.dart`, list height helper).

### 0.2 Refactor existing four widgets to delegate

- `SearchableDropdownPlus` → internal panel/trigger
- `MultiSelectDropdownPlus` → same
- `SearchableDropdown` → same
- `MultiSelectDropdown` → same

**Acceptance:** All existing tests pass; no public API diff.

### 0.3 Additive parameters (all four legacy widgets)

| Parameter | Default | Notes |
|-----------|---------|--------|
| `enabled` | `true` | Block open/search when false |
| `autofocusSearch` | `false` | Focus search field when panel opens |
| `emptyBuilder` | `null` | Custom empty state; falls back to `noResultsText` |
| `loadingBuilder` | `null` | Custom loading; falls back to spinner + `loadingText` |
| `errorBuilder` | `null` | `(BuildContext context, Object error, VoidCallback retry)` |
| `semanticsLabel` | `null` | Accessibility label for trigger |
| `minSearchLength` | `0` | Skip `onSearch` until query length ≥ N |

**Deliverable:** `1.1.0` — polish and shared internals; legacy API unchanged in shape.

---

## Phase 1 — Form integration

**Target version:** `1.1.0` or `1.1.1`  
**Export:** Main barrel (additive)

### New widgets (legacy `DropdownItem` model)

```
SearchableDropdownPlusFormField<C, S>
MultiSelectDropdownPlusFormField<C, S>
SearchableDropdownFormField
MultiSelectDropdownFormField
```

**Parameters:** `validator`, `onSaved`, `autovalidateMode`, `initialValue` / `initialValues`, plus passthrough of parent widget params.

**Tests:** Validator errors, `onSaved`, controlled vs uncontrolled value.

---

## Phase 2 — Typed generic API (opt-in)

**Target version:** `1.2.0` (document as **preview** until API stabilizes)  
**Risk:** Medium — new surface area, no changes to default import

### 2.1 New entry library

```dart
import 'package:dropdown_plus_bloc/typed.dart';
```

```dart
// lib/typed.dart
library dropdown_plus_typed;

export 'src/typed/...';
```

### 2.2 Core types

```
lib/src/typed/
  typed_dropdown_callbacks.dart      # onChanged, onSearch, onStateChange typedefs
  typed_dropdown_controller.dart     # DropdownPlusController<T> (optional in 1.2)
```

### 2.3 Widget naming

| Legacy (1.0) | Typed (new) |
|--------------|-------------|
| `SearchableDropdownPlus<C, S>` | `TypedSearchableDropdownPlus<T, C, S>` |
| `MultiSelectDropdownPlus<C, S>` | `TypedMultiSelectDropdownPlus<T, C, S>` |
| `SearchableDropdown` | `TypedSearchableDropdown<T>` |
| `MultiSelectDropdown` | `TypedMultiSelectDropdown<T>` |

> **Do not** reuse `SearchableDropdown<T>` on the main export — that name is taken by the non-BLoC 1.0 widget.

### 2.4 Typed API surface (single-select Plus example)

```dart
TypedSearchableDropdownPlus<User, UsersCubit, UsersState>(
  cubit: cubit,
  hintText: 'Select user',
  itemLabel: (user) => user.name,
  value: selectedUser,
  onChanged: (User? user) => ...,
  onSearch: cubit.search,
  onStateChange: (state, updateItems, updateLoading) {
    if (state is UsersLoaded) {
      updateItems(state.users); // List<User>, not List<DropdownItem>
      updateLoading(false);
    }
  },
  itemEquals: (a, b) => a.id == b.id,
  debounceDuration: const Duration(milliseconds: 400),
  errorBuilder: (context, error, retry) => ...,
)
```

### 2.5 Legacy vs typed comparison

| Legacy | Typed |
|--------|-------|
| `updateList(List<DropdownItem>)` | `updateItems(List<T>)` |
| `selectedValue` | `value: T?` |
| `onSelectionChanged(DropdownItem)` | `onChanged(T?)` |
| Manual `DropdownItem(value:, label:)` mapping | `itemLabel: (T) => String` |

### 2.6 Implementation strategy

- Typed widgets are **thin adapters** over shared internal UI from Phase 0.
- Adapter maps `T` ↔ display via `itemLabel` and `itemEquals`.
- Legacy `SearchableDropdownPlus` **unchanged** on the main export; may share internals only.

### 2.7 BLoC `onStateChange` helper (optional)

```
lib/src/helpers/dropdown_state_mapper.dart
```

Pattern-matching helper for common loading/loaded/error states — usable from legacy and typed APIs.

### 2.8 Bridge helpers (gradual migration)

```dart
extension DropdownItemListX<T> on List<T> {
  List<DropdownItem<T>> toDropdownItems(String Function(T) label);
}
```

---

## Phase 3 — Scale and accessibility

**Target version:** `1.2.x` / `1.3.0`

### 3.1 Performance

- Replace `ListView.separated(shrinkWrap: true)` with **`ListView.builder`** in shared `dropdown_item_list.dart`.
- Ensure `menuMaxHeight` is respected consistently (single-select fixed in 1.0; verify multi-select).

### 3.2 Pagination (optional parameters)

```dart
onLoadMore: () => cubit.fetchNextPage(),
hasMore: state.hasMore,
isLoadingMore: state.isLoadingMore,
```

Scroll listener at list bottom; cubit still owns data and state.

### 3.3 Accessibility and keyboard

- `Semantics` on trigger, items, and selected state.
- `FocusNode` on trigger and search field.
- Arrow keys / Enter / Escape (desktop/web) — defer to **3b** if large effort.

---

## Phase 4 — Controller and DX

**Target version:** `1.3.0`

```dart
final controller = DropdownPlusController<User>();

controller.select(user);
controller.clear();
controller.open();   // optional
controller.close();
```

Typed widgets first; legacy may accept optional controller mapping to `DropdownItem` later.

---

## Phase 5 — Documentation

### New docs (to add alongside this file)

| File | Purpose |
|------|---------|
| `TYPED_API.md` | Typed API reference and when to use it |
| `MIGRATION_TO_TYPED.md` | Gradual legacy → typed migration |
| `COOKBOOK.md` | Error states, forms, pagination recipes |

### README structure (target)

1. Quick start — **legacy BLoC** (default for 1.0 users)
2. “New: Typed API” — link to `typed.dart`
3. Feature comparison table (legacy vs typed)
4. When to migrate (greenfield vs existing apps)

### Example app sections (target)

1. BLoC legacy (current)
2. BLoC typed
3. Form fields
4. Error + retry
5. Debounce + pagination (optional)

---

## Phase 6 — Deprecation policy (future)

| Version | Action |
|---------|--------|
| **1.2** | Introduce typed API; **no** deprecations |
| **1.5** | README recommends typed for new projects |
| **2.0** | `@Deprecated` on item-based widgets if adoption justifies; **still exported** |
| **3.0** | Remove legacy only with strong adoption evidence and migration path |

**Never** remove `SearchableDropdownPlus` without a major version and at least one release cycle of deprecation.

---

## Release schedule (proposed)

| Release | Focus | Risk |
|---------|--------|------|
| **1.1.0** | Internal refactor + `enabled`, builders, `errorBuilder`, form fields | Low |
| **1.2.0** | `typed.dart` + `Typed*Plus` + `Typed*` widgets (preview) | Medium |
| **1.2.1** | Feedback fixes on typed API | Low |
| **1.3.0** | `ListView.builder`, pagination, controller, a11y basics | Medium |
| **2.0.0** | Deprecations only (optional, far future) | High |

---

## Testing outline

```
test/
  legacy/                         # existing 1.0 tests (keep)
  typed/
    typed_searchable_plus_test.dart
    typed_multi_plus_test.dart
    typed_searchable_test.dart
    adapter_mapping_test.dart
  internal/
    debounced_callback_test.dart
    dropdown_list_height_test.dart
  forms/
    form_field_validation_test.dart
  golden/                         # optional theme presets
```

**Critical typed tests:**

- `onStateChange` receives `List<User>` not `List<DropdownItem>`
- `onChanged` is `User?` without cast
- Cubit **not** closed on dispose (regression)
- Legacy + typed produce equivalent UI for the same data

---

## Target file structure

```
lib/
  dropdown_plus_bloc.dart       # 1.0 exports (unchanged)
  typed.dart                    # NEW opt-in
  src/
    widgets/                    # legacy 1.0 (delegate to internal)
    typed/                      # NEW
      typed_searchable_dropdown_plus.dart
      typed_multi_select_dropdown_plus.dart
      typed_searchable_dropdown.dart
      typed_multi_select_dropdown.dart
      typed_form_fields.dart
    internal/                   # shared UI (Phase 0)
    helpers/                    # state mapper, item mapping
    models/                     # unchanged
    utils/
```

---

## Open decisions

Resolve before implementation:

1. **Prefix:** `Typed*` vs factory constructors vs namespace-only `typed.dart`?
2. **`itemBuilder` signature:** add `BuildContext` (typed only) or match legacy `(item, isSelected)`?
3. **Form fields:** ship in 1.1 for legacy only, or wait for typed form fields?
4. **Experimental flag:** mark typed library as preview in README until 1.3?

**Recommendation:** `Typed*` prefix + separate `typed.dart` import; form fields on legacy in 1.1; typed marked preview until 1.2.1.

---

## Recommended execution order

1. **Phase 0** — internal extract + 1.1 additive params (safest win)
2. **Phase 1** — form fields on legacy API
3. **Phase 2** — `typed.dart` MVP: `TypedSearchableDropdownPlus` first
4. Expand typed to multi-select and non-BLoC variants
5. **Phases 3–4** — performance, pagination, controller, accessibility

---

## Status tracker

| Phase | Status | Version |
|-------|--------|---------|
| 1.0 stable release | **Done** | `1.0.0` |
| Phase 0 — Foundation | Not started | `1.1.0` |
| Phase 1 — Form fields | Not started | `1.1.x` |
| Phase 2 — Typed API | Not started | `1.2.0` |
| Phase 3 — Scale / a11y | Not started | `1.3.0` |
| Phase 4 — Controller | Not started | `1.3.0` |
| Phase 5 — Docs | In progress | — |
| Phase 6 — Deprecation | Future | `2.0+` |
