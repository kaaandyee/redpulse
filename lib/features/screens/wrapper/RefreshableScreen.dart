import 'package:flutter/material.dart';

/// A mixin that provides pull-to-refresh functionality for screens
/// that need to refresh data from Firebase.
mixin RefreshableScreen<T extends StatefulWidget> on State<T> {
  /// Flag to track if a refresh operation is in progress
  bool _isRefreshing = false;

  /// Method that must be implemented by classes using this mixin
  /// to perform the actual data refresh operations
  Future<void> refreshData();

  /// Helper method to create a RefreshIndicator with consistent styling
  Widget buildRefreshableBody(Widget child) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_isRefreshing) return;

        setState(() {
          _isRefreshing = true;
        });

        try {
          await refreshData();
        } catch (e) {
          // Handle errors, possibly show a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to refresh: $e'),
              backgroundColor: Colors.red,
            ),
          );
        } finally {
          if (mounted) {
            setState(() {
              _isRefreshing = false;
            });
          }
        }
      },
      color: const Color.fromARGB(250, 212, 61, 61), // Match RedPulse primary color
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: 20,
      edgeOffset: 0,
      child: child,
    );
  }
}