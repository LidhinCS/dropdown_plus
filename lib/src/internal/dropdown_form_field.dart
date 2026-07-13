import 'package:flutter/material.dart';

/// Wraps a dropdown with standard [FormField] error text below.
Widget dropdownFormFieldDecoration({
  required FormFieldState<dynamic> state,
  required Widget dropdown,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      dropdown,
      if (state.hasError)
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            state.errorText!,
            style: TextStyle(
              color: Theme.of(state.context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ),
    ],
  );
}
