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
    _resetInactivityTimer();
  }

  /// Set payment status to prevent logout during payment
  void setPaymentInProgress(bool inProgress) {
    _isPaymentInProgress = inProgress;
    print('💳 AutoLogout: Payment in progress: $inProgress');
    
    if (inProgress) {
      // Pause the timer during payment
      _stopInactivityTimer();
    } else {
      // Resume monitoring after payment
      if (_isLoggedIn) {
        _startInactivityTimer();
      }
    }
  }

  /// Start the inactivity timer
  void _startInactivityTimer() {
    _stopInactivityTimer(); // Clear any existing timer
    
    // Ensure activity time is initialized
    _lastActivityTime ??= DateTime.now();
    
    _inactivityTimer = Timer(_inactivityTimeout, () {
      _handleInactivityTimeout();
    });
    
    print('⏰ AutoLogout: Started inactivity timer (${_inactivityTimeout.inMinutes} minutes)');
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
      // Perform logout
      await AuthService.logoutUser();
      _isLoggedIn = false;
      _stopInactivityTimer();
      
      // Notify the app about auto logout
      if (_onAutoLogout != null) {
        _onAutoLogout!();
      }
      
      print('✅ AutoLogout: User logged out due to inactivity');
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
    
    // Pause the inactivity timer (we'll check elapsed time on resume)
    _stopInactivityTimer();
    
    print('📱 AutoLogout: App went to background at ${_backgroundTime}');
  }

  /// Handle app coming back to foreground
  Future<void> onAppResumed() async {
    if (!_isLoggedIn) return;
    
    print('📱 AutoLogout: App resumed from background');
    
    // Check if user was in background for too long
    if (_backgroundTime != null) {
      final backgroundDuration = DateTime.now().difference(_backgroundTime!);
      print('📱 AutoLogout: Was in background for ${backgroundDuration.inMinutes} minutes');
      
      // If user was away for more than the timeout period, logout immediately
      if (backgroundDuration >= _inactivityTimeout) {
        print('⏰ AutoLogout: Background time exceeded timeout - logging out');
        await _handleInactivityTimeout();
        return;
      }
      
      // Clear background time
      _backgroundTime = null;
    }
    
    // Resume monitoring if not in payment
    if (!_isPaymentInProgress) {
      _lastActivityTime = DateTime.now(); // Reset activity time
      _startInactivityTimer();
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
        // Don't do anything here, wait for paused or resumed
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.hidden:
        // App is hidden (iOS specific)
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _autoLogoutService.recordActivity(),
      onPanDown: (_) => _autoLogoutService.recordActivity(),
      onScaleStart: (_) => _autoLogoutService.recordActivity(),
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
