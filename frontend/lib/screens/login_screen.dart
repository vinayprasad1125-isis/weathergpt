import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config.dart';
import '../main.dart'; // To access MainNavigator
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(
          clientId: '201659855993-tb1pdcdd2tv753h19u7c82qdhpgo4mo5.apps.googleusercontent.com',
          scopes: ['email', 'profile', 'openid'],
        )
      : GoogleSignIn(
          serverClientId: '201659855993-tb1pdcdd2tv753h19u7c82qdhpgo4mo5.apps.googleusercontent.com',
          scopes: ['email', 'profile', 'openid'],
        );

  Future<void> _handleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // On GIS web, signIn() can hang forever if the popup is blocked.
      // A 60s timeout ensures the loading state always resets.
      final GoogleSignInAccount? account = await _googleSignIn
          .signIn()
          .timeout(const Duration(seconds: 60), onTimeout: () => null);
      if (account != null) {
        await _authenticateWithBackend(account);
      }
    } catch (error) {
      if (error.toString().contains('popup_closed')) {
        debugPrint('User closed the sign in popup');
      } else {
        debugPrint('Sign in error: $error');
        _showError('Sign in failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _authenticateWithBackend(GoogleSignInAccount account) async {
    try {
      final GoogleSignInAuthentication auth = await account.authentication;
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/api/v1/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': auth.idToken,
          'access_token': auth.accessToken,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigator()),
          );
        }
      } else {
        _showError('Backend authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Authentication failed: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Welcome to WeatherGPT',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please sign in to continue.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _handleSignIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
