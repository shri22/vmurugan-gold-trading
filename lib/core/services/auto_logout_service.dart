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
      _startInactivityTimer();
    }
  }

  /// Start monitoring user activity
  void startMonitoring() {
    _isLoggedIn = true;
    _startInactivityTimer();
  }

  /// Stop monitoring (when user logs out)
  void stopMonitoring() {
    _isLoggedIn = false;
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
  void _handleInactivityTimeout() async {
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

  /// Dispose resources
  void dispose() {
    _stopInactivityTimer();
    _onAutoLogout = null;
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

class _AutoLogoutWrapperState extends State<AutoLogoutWrapper> {
  final AutoLogoutService _autoLogoutService = AutoLogoutService();

  @override
  void initState() {
    super.initState();
    _autoLogoutService.initialize(onAutoLogout: widget.onAutoLogout);
  }

  @override
  void dispose() {
    _autoLogoutService.dispose();
    super.dispose();
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
