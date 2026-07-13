# Typed API (preview)

Opt-in generic API — use your domain type `T` instead of `DropdownItem<T>`.

```dart
import 'package:dropdown_plus_bloc/typed.dart';
```

The default export (`dropdown_plus_bloc.dart`) is unchanged. Legacy widgets are not deprecated.

## When to use

| Use typed API | Use legacy API |
|---------------|----------------|
| New projects, strong domain models | Existing apps on `DropdownItem` |
| Avoid manual `DropdownItem` mapping | Already wrapped in your own mappers |

## Single select (BLoC)

```dart
TypedSearchableDropdownPlus<User, UsersCubit, UsersState>(
  cubit: cubit,
  hintText: 'Select user',
  itemLabel: (user) => user.name,
  value: selectedUser,
  onChanged: (User? user) => setState(() => selectedUser = user),
  onSearch: cubit.search,
  onStateChange: (state, updateItems, updateLoading) {
    if (state is UsersLoaded) {
      updateItems(state.users);
      updateLoading(false);
    }
  },
  itemEquals: (a, b) => a.id == b.id,
)
```

## Single select (no BLoC)

```dart
TypedSearchableDropdown<User>(
  hintText: 'Select user',
  items: users,
  isLoading: isLoading,
  itemLabel: (u) => u.name,
  value: selected,
  onChanged: (user) => setState(() => selected = user),
)
```

## Multi select

- `TypedMultiSelectDropdownPlus<T, C, S>` — `values` / `onChanged: (List<T>)`
- `TypedMultiSelectDropdown<T>` — same without BLoC

## Legacy bridge

```dart
final items = users.toDropdownItems((u) => u.name);
```

## Widget map

| Legacy | Typed |
|--------|-------|
| `SearchableDropdownPlus<C,S>` | `TypedSearchableDropdownPlus<T,C,S>` |
| `MultiSelectDropdownPlus<C,S>` | `TypedMultiSelectDropdownPlus<T,C,S>` |
| `SearchableDropdown` | `TypedSearchableDropdown<T>` |
| `MultiSelectDropdown` | `TypedMultiSelectDropdown<T>` |
