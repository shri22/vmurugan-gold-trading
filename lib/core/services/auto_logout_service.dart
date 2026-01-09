import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Service to handle automatic logout after inactivity
class AutoLogoutService {
  static final AutoLogoutService _instance = AutoLogoutService._internal();
  factory AutoLogoutService() => _instance;
  AutoLogoutService._internal();

  // Configuration
  static const Duration _inactivityTimeout = Duration(minutes: 5);
  
  // State tracking
  Timer? _inactivityTimer;
  bool _isPaymentInProgress = false;
  bool _isLoggedIn = false;
  DateTime? _lastActivityTime;
  DateTime? _backgroundTime; // Track when app went to background
  
  static const String _lastActivityTimestampKey = 'last_activity_timestamp';
  static const String _isPaymentInProgressKey = 'is_payment_in_progress';
  
  // Callback for logout
  VoidCallback? _onAutoLogout;

  /// Initialize the auto logout service
  void initialize({VoidCallback? onAutoLogout}) {
    _onAutoLogout = onAutoLogout;
    _checkLoginStatus();
  }

  /// Check if user is logged in and start monitoring if needed
  Future<void> _checkLoginStatus() async {
    _isLoggedIn = await AuthService.isLoggedIn();
    if (_isLoggedIn) {
      _lastActivityTime = DateTime.now(); // Initialize activity time
      _startInactivityTimer();
    }
  }

  /// Start monitoring user activity
  void startMonitoring() {
    _isLoggedIn = true;
    _lastActivityTime = DateTime.now(); // Initialize activity time
    _startInactivityTimer();
  }

  /// Stop monitoring (when user logs out)
  void stopMonitoring() {
    _isLoggedIn = false;
    _lastActivityTime = null; // Clear activity time
    _stopInactivityTimer();
  }

  /// Record user activity (reset the timer)
  void recordActivity() {
    if (!_isLoggedIn) return;
    
    _lastActivityTime = DateTime.now();
    _saveLastActivityToPrefs(); // Persist the timestamp
    _resetInactivityTimer();
  }

  /// Persist activity timestamp to handle app kills/backgrounding
  Future<void> _saveLastActivityToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActivityTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ AutoLogout: Error saving timestamp: $e');
    }
  }

  /// Set payment status to prevent logout during payment
  Future<void> setPaymentInProgress(bool inProgress) async {
    _isPaymentInProgress = inProgress;
    print('💳 AutoLogout: Payment in progress: $inProgress');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isPaymentInProgressKey, inProgress);
    
    if (inProgress) {
      _stopInactivityTimer();
    } else {
      if (_isLoggedIn) {
        _startInactivityTimer();
      }
    }
  }

  /// Start the inactivity timer with optional custom timeout
  void _startInactivityTimer({Duration? customTimeout}) {
    _stopInactivityTimer(); // Clear any existing timer
    
    // Ensure activity time is initialized
    _lastActivityTime ??= DateTime.now();
    
    final timeout = customTimeout ?? _inactivityTimeout;
    
    _inactivityTimer = Timer(timeout, () {
      _handleInactivityTimeout();
    });
    
    print('⏰ AutoLogout: Started inactivity timer (${timeout.inMinutes}m ${timeout.inSeconds % 60}s)');
  }

  /// Stop the inactivity timer
  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Reset the inactivity timer (user was active)
  void _resetInactivityTimer() {
    if (_isLoggedIn && !_isPaymentInProgress) {
      _startInactivityTimer();
    }
  }

  /// Handle inactivity timeout
  Future<void> _handleInactivityTimeout() async {
    // Don't logout if payment is in progress
    if (_isPaymentInProgress) {
      print('💳 AutoLogout: Skipping logout - payment in progress');
      return;
    }

    // Don't logout if user is not logged in
    if (!_isLoggedIn) {
      print('🔒 AutoLogout: Skipping logout - user not logged in');
      return;
    }

    print('⏰ AutoLogout: Inactivity timeout reached - logging out user');
    
    try {
      // CLEAR IN-MEMORY STATE FIRST to avoid loops
      _isLoggedIn = false;
      _stopInactivityTimer();
      _lastActivityTime = null;
      _backgroundTime = null;

      // Perform persistent logout
      await AuthService.logoutUser();
      
      // Clear the persistent timestamp so we don't loop
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastActivityTimestampKey);
      await prefs.setBool(_isPaymentInProgressKey, false);
      
      print('✅ AutoLogout: User logged out due to inactivity');

      // Notify the app about auto logout
      if (_onAutoLogout != null) {
        _onAutoLogout!();
      }
    } catch (e) {
      print('❌ AutoLogout: Error during auto logout: $e');
    }
  }

  /// Get remaining time before auto logout
  Duration? getRemainingTime() {
    if (!_isLoggedIn || _isPaymentInProgress || _lastActivityTime == null) {
      return null;
    }
    
    final elapsed = DateTime.now().difference(_lastActivityTime!);
    final remaining = _inactivityTimeout - elapsed;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if auto logout is active
  bool get isActive => _isLoggedIn && !_isPaymentInProgress && _inactivityTimer != null;

  /// Get current payment status
  bool get isPaymentInProgress => _isPaymentInProgress;

  /// Handle app going to background
  void onAppPaused() {
    if (!_isLoggedIn) return;
    
    // Record when app went to background
    _backgroundTime = DateTime.now();
    _saveLastActivityToPrefs(); // CRITICAL: Save exact time app was left
    
    // Pause the inactivity timer (we'll check elapsed time on resume)
    _stopInactivityTimer();
    
    print('📱 AutoLogout: App went to background at ${_backgroundTime}');
  }

  /// Handle app coming back to foreground
  Future<void> onAppResumed() async {
    _isLoggedIn = await AuthService.isLoggedIn();
    if (!_isLoggedIn) return;
    
    print('📱 AutoLogout: App resumed from background');
    
    // 1. Check persistent timestamp (Bulletproof)
    final prefs = await SharedPreferences.getInstance();
    final lastTs = prefs.getInt(_lastActivityTimestampKey);
    final inPayment = prefs.getBool(_isPaymentInProgressKey) ?? false;

    if (lastTs != null && !inPayment) {
      final lastActivity = DateTime.fromMillisecondsSinceEpoch(lastTs);
      final elapsed = DateTime.now().difference(lastActivity);
      
      print('📱 AutoLogout: Persistent check - elapsed: ${elapsed.inMinutes} mins');
      
      if (elapsed >= _inactivityTimeout) {
        print('⏰ AutoLogout: Persistent time exceeded - forcing logout');
        await _handleInactivityTimeout();
        return;
      }
    }
    
    // 2. Check in-memory background time as fallback
    if (_backgroundTime != null && !inPayment) {
      final backgroundDuration = DateTime.now().difference(_backgroundTime!);
      if (backgroundDuration >= _inactivityTimeout) {
        print('⏰ AutoLogout: Memory time exceeded - forcing logout');
        await _handleInactivityTimeout();
        return;
      }
    }
    
    // Clear background time
    _backgroundTime = null;
    
    // Resume monitoring if not in payment
    if (!_isPaymentInProgress) {
      // Use the existing _lastActivityTime if available to preserve remaining time
      // or set to now if it was null (shouldn't happen for logged-in user)
      _lastActivityTime ??= DateTime.now();
      
      final elapsedSinceLastActivity = DateTime.now().difference(_lastActivityTime!);
      final remaining = _inactivityTimeout - elapsedSinceLastActivity;
      
      if (remaining.isNegative || remaining == Duration.zero) {
        print('⏰ AutoLogout: No time left on resume - forcing logout');
        await _handleInactivityTimeout();
      } else {
        print('⏰ AutoLogout: Resuming monitoring with ${remaining.inSeconds} seconds remaining');
        _startInactivityTimer(customTimeout: remaining);
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _stopInactivityTimer();
    _onAutoLogout = null;
    _backgroundTime = null;
  }
}

/// Widget to wrap around the app to automatically track user interactions
class AutoLogoutWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAutoLogout;

  const AutoLogoutWrapper({
    super.key,
    required this.child,
    this.onAutoLogout,
  });

  @override
  State<AutoLogoutWrapper> createState() => _AutoLogoutWrapperState();
}

class _AutoLogoutWrapperState extends State<AutoLogoutWrapper> with WidgetsBindingObserver {
  final AutoLogoutService _autoLogoutService = AutoLogoutService();

  @override
  void initState() {
    super.initState();
    _autoLogoutService.initialize(onAutoLogout: widget.onAutoLogout);
    // Start observing app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Stop observing app lifecycle changes
    WidgetsBinding.instance.removeObserver(this);
    _autoLogoutService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App went to background (user switched to another app)
        _autoLogoutService.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        // App came back to foreground
        _autoLogoutService.onAppResumed();
        break;
      case AppLifecycleState.inactive:
        // App is transitioning (e.g., incoming call, app switcher)
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _autoLogoutService.recordActivity(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
