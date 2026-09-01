import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/admin_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    final auth = Provider.of<AuthService>(context, listen: false);

    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.isEmpty) {
      showModernToast(
        context: context,
        message: 'Email dan password wajib diisi',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await auth.login(_emailCtrl.text, _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      showModernToast(
        context: context,
        message: 'Email atau password salah',
        type: ToastType.error,
      );
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 400;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: size.height - MediaQuery.of(context).padding.top,
            child: Stack(
              children: [
                // Main Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ASIQ Logo
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'A',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmall ? 56.0 : 72.0,
                                color: const Color(0xFF5393E0),
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'S',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmall ? 56.0 : 72.0,
                                color: const Color(0xFF3579C5),
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'I',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmall ? 56.0 : 72.0,
                                color: const Color(0xFF1F6DB8),
                                height: 1.0,
                              ),
                            ),
                            Text(
                              'Q',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmall ? 56.0 : 72.0,
                                color: const Color(0xFF0860AA),
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Underline
                        Container(
                          width: isSmall ? 80.0 : 120.0,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF5393E0),
                                Color(0xFF0860AA),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Welcome Title
                        Text(
                          'Selamat Datang',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isSmall ? 26 : 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF003974),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          'Silakan masuk ke akun guru Anda.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            color: const Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Email/Username Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'Email',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2FBFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFDBE4E4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF005DA7).withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 15,
                                  color: const Color(0xFF1F2937),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'guru@sekolah.id',
                                  hintStyle: GoogleFonts.beVietnamPro(
                                    fontSize: 15,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Icon(
                                      Icons.email_outlined,
                                      size: 22,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'Password',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2FBFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFDBE4E4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF005DA7).withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 15,
                                  color: const Color(0xFF1F2937),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  hintStyle: GoogleFonts.beVietnamPro(
                                    fontSize: 15,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Icon(
                                      Icons.lock_outline,
                                      size: 22,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 22,
                                      color: const Color(0xFF6B7280),
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 18,
                                  ),
                                ),
                                onSubmitted: (_) => _handleLogin(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF005DA7).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: const Border(
                                bottom: BorderSide(
                                  color: Color(0xFF004883),
                                  width: 4,
                                ),
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005DA7),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.only(
                                  top: 18,
                                  bottom: 22,
                                  left: 24,
                                  right: 24,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: const Color(0xFF005DA7).withValues(alpha: 0.6),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Masuk',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Created by KKNT UNESA 2026',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
