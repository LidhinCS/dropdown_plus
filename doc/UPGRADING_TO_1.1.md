# Upgrading to 1.1

## Summary

**Version 1.1 is backward compatible.** Existing call sites work without changes.

```yaml
dependencies:
  dropdown_plus_bloc: ^1.1.0
```

## What's new (all four widgets)

Optional parameters — defaults preserve 1.0 behaviour:

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `enabled` | `true` | Disable opening and search |
| `autofocusSearch` | `false` | Focus search field when panel opens |
| `emptyBuilder` | `null` | Custom empty state |
| `loadingBuilder` | `null` | Custom loading state |
| `error` | `null` | Controlled error to show in panel |
| `onRetry` | `null` | Retry action (defaults to re-search) |
| `errorBuilder` | `null` | Custom error UI |
| `semanticsLabel` | `null` | Accessibility label on trigger |
| `minSearchLength` | `0` | Min chars before `onSearch` (empty query always fires) |

## Example: error + retry

```dart
SearchableDropdownPlus<UsersCubit, UsersState>(
  cubit: cubit,
  error: state is UsersError ? state.message : null,
  onRetry: cubit.reload,
  hintText: 'Select user',
  // ...
)
```

Wrap in `BlocBuilder` if the parent needs to pass `error` from cubit state.

## Internal refactor

Widget UI is now built from shared components in `lib/src/internal/`. Public API names are unchanged.
