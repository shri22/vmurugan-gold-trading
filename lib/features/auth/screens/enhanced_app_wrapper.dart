import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../onboarding/screens/onboarding_screen.dart';
import 'enhanced_phone_entry_screen.dart';
import 'quick_mpin_login_screen.dart';
import '../../../main.dart';

/// Enhanced app wrapper that handles the new authentication flow
/// This can be used optionally without breaking existing functionality
class EnhancedAppWrapper extends StatefulWidget {
  const EnhancedAppWrapper({super.key});

  @override
  State<EnhancedAppWrapper> createState() => _EnhancedAppWrapperState();
}

class _EnhancedAppWrapperState extends State<EnhancedAppWrapper> {
  AuthState? _authState;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      print('🔍 EnhancedAppWrapper: Checking authentication state...');
      
      // Check if enhanced flow is enabled
      final isEnhancedEnabled = await AuthService.isEnhancedFlowEnabled();
      
      if (!isEnhancedEnabled) {
        // Enhanced flow is disabled, use original onboarding
        print('📱 EnhancedAppWrapper: Enhanced flow disabled, using original flow');
        setState(() {
          _authState = AuthState.needsOnboarding;
          _isLoading = false;
        });
        return;
      }
      
      // Get current auth state
      final authState = await AuthService.getAuthState();
      print('🔍 EnhancedAppWrapper: Auth state: $authState');
      
      setState(() {
        _authState = authState;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ EnhancedAppWrapper: Error checking auth state: $e');
      setState(() {
        _authState = AuthState.needsOnboarding;
        _isLoading = false;
      });
    }
  }

  Widget _buildScreenForState(AuthState state) {
    switch (state) {
      case AuthState.needsOnboarding:
        return const OnboardingScreen();
      
      case AuthState.needsPhoneNumber:
        return const EnhancedPhoneEntryScreen();
      
      case AuthState.needsMpinLogin:
        // Show quick MPIN login for returning users
        return const QuickMpinLoginScreen();
      
      case AuthState.loggedIn:
        return const HomePage();
      
      default:
        return const OnboardingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _buildScreenForState(_authState!);
  }
}

/// Helper widget to enable enhanced authentication flow
class EnhancedAuthFlowToggle extends StatefulWidget {
  final Widget child;
  
  const EnhancedAuthFlowToggle({
    super.key,
    required this.child,
  });

  @override
  State<EnhancedAuthFlowToggle> createState() => _EnhancedAuthFlowToggleState();
}

class _EnhancedAuthFlowToggleState extends State<EnhancedAuthFlowToggle> {
  bool _isEnhanced = false;

  @override
  void initState() {
    super.initState();
    _loadEnhancedState();
  }

  Future<void> _loadEnhancedState() async {
    final isEnhanced = await AuthService.isEnhancedFlowEnabled();
    setState(() {
      _isEnhanced = isEnhanced;
    });
  }

  Future<void> _toggleEnhancedFlow(bool enabled) async {
    await AuthService.setEnhancedFlowEnabled(enabled);
    setState(() {
      _isEnhanced = enabled;
    });
    
    // Show restart message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled 
                ? 'Enhanced authentication enabled. Restart app to see changes.'
                : 'Enhanced authentication disabled. Restart app to see changes.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enhanced Authentication Flow',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enable the new step-by-step authentication flow with phone verification, OTP, and MPIN setup.',
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Enhanced Flow'),
              subtitle: Text(
                _isEnhanced 
                    ? 'New users will go through phone → OTP → MPIN setup'
                    : 'Uses the original login screen',
              ),
              value: _isEnhanced,
              onChanged: _toggleEnhancedFlow,
            ),
            const SizedBox(height: 24),
            if (_isEnhanced) ...[
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enhanced Flow Features:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('• Phone number entry first'),
                      Text('• Automatic registration check'),
                      Text('• OTP verification for new users'),
                      Text('• MPIN setup after registration'),
                      Text('• MPIN-only login for returning users'),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => widget.child,
                    ),
                  );
                },
                child: const Text('Continue to App'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
