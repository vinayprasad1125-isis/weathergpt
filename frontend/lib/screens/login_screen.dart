import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config.dart';
import '../main.dart'; // To access MainNavigator

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = kIsWeb
          ? GoogleSignIn(
              clientId: '201659855993-tb1pdcdd2tv753h19u7c82qdhpgo4mo5.apps.googleusercontent.com',
              scopes: ['email', 'profile', 'openid'],
            )
          : GoogleSignIn(
              serverClientId: '201659855993-tb1pdcdd2tv753h19u7c82qdhpgo4mo5.apps.googleusercontent.com',
              scopes: ['email', 'profile', 'openid'],
            );
      
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        final String? idToken = auth.idToken;
        final String? accessToken = auth.accessToken;
        
        if (idToken != null || accessToken != null) {
          // Send token(s) to our FastAPI backend
          final response = await http.post(
            Uri.parse('${Config.apiBaseUrl}/api/v1/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id_token': idToken,
              'access_token': accessToken,
            }),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final String accessToken = data['access_token'];
            
            // Here you would normally save the access_token securely
            // e.g. using flutter_secure_storage or shared_preferences
            print('Successfully logged in. Access Token: $accessToken');
            
            // Navigate to main app
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainNavigator()),
              );
            }
          } else {
            _showError('Backend authentication failed: ${response.body}');
          }
        } else {
          _showError('Failed to get any token from Google.');
        }
      }
    } catch (error) {
      print('Sign in error: $error');
      _showError('Sign in failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
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
                  color: Colors.grey,
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
