import 'package:flutter/material.dart';
import 'package:wordnest/services/card_sync_service.dart';
import 'dart:async';
import 'package:wordnest/services/auth_service.dart';
import 'package:wordnest/screens/login_screen.dart';
import 'package:wordnest/utils/event_bus.dart';

class AppInitializer {
  static final Completer<void> _initializerCompleter = Completer<void>();
  static final CardSyncService _cardSyncService = CardSyncService();
  static final AuthService _authService = AuthService();

  static Future<void> runAfterStart(BuildContext context) async {
    if (!_initializerCompleter.isCompleted) {
      print('This runs after the app has started.');

      bool isAuthenticated = await _authService.authenticate();

      if (isAuthenticated) {
        // If authentication is successful, proceed with card syncing
        print('Authentication successful, syncing cards...');
        await _cardSyncService.fetchAndSyncCards();

        eventBus.fire(SyncCompleteEvent());
      } else {
        // If authentication fails, navigate to the login screen
        print('Authentication failed, redirecting to LoginScreen...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return; // Stop further execution
      }

      // Mark the initialization as completed
      _initializerCompleter.complete();
    }
    await _initializerCompleter.future;
  }
}

// Define an event class
class SyncCompleteEvent {}
