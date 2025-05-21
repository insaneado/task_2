import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const PasswordGeneratorApp());
}

class PasswordGeneratorApp extends StatelessWidget {
  const PasswordGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Password Generator',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5D4DB3),
        brightness: Brightness.light,
        fontFamily: GoogleFonts.roboto().fontFamily,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5D4DB3),
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.roboto().fontFamily,
      ),
      themeMode: ThemeMode.system,
      home: const PasswordGeneratorScreen(),
    );
  }
}

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen>
    with SingleTickerProviderStateMixin {
  // Password settings
  int pwLength = 16;
  bool hasUpper = true;
  bool hasLower = true;
  bool hasNums = true;
  bool hasSpecial = false;

  // Generated password
  String currentPass = '';

  //feature
  int _passwordGenCount = 0;
  bool _easterEggUnlocked = false;

  // Animation controllers
  late AnimationController animController;
  late Animation<double> animation;

  // Character sets
  static const String _UPPERCASE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _special = '!@#\$%^&*()_+-=[]{}|;:,.?';

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    //  animation
    animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: animController, curve: Curves.easeOutBack),
    );

    // Generate initial password
    Future.delayed(const Duration(milliseconds: 100), () {
      _makeNewPassword();
    });
  }

  @override
  void dispose() {
    animController.dispose();
    super.dispose();
  }

  void _makeNewPassword() {
    if (!_hasAnyCharTypes()) {
      setState(() {
        currentPass = '';
      });
      return;
    }

    // Easter egg counter
    _passwordGenCount++;
    if (_passwordGenCount >= 10 && !_easterEggUnlocked) {
      setState(() {
        _easterEggUnlocked = true;
      });
    }

    // Build character pool based on selected options
    String chars = '';
    if (hasUpper) chars += _UPPERCASE;
    if (hasLower) chars += _lowercase;
    if (hasNums) chars += _numbers;
    if (hasSpecial) chars += _special;

    // Generate random password with secure RNG
    var rng = Random.secure();
    var result = StringBuffer();

    for (var i = 0; i < pwLength; i++) {
      result.write(chars[rng.nextInt(chars.length)]);
    }

    if (mounted) {
      setState(() {
        currentPass = result.toString();
      });

      animController.reset();
      animController.forward();
    }
  }

  void _copyPassword() {
    if (currentPass.isEmpty) return;

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: currentPass)).then((_) {
      //  feedback snackbar
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 280,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              Text(
                'Password copied!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    });

    animController.reset();
    animController.forward();
  }

  bool _hasAnyCharTypes() {
    return hasUpper || hasLower || hasNums || hasSpecial;
  }

  String _getStrengthText() {
    if (currentPass.isEmpty) return 'None';

    var pts = 0;

    // Points for length
    if (pwLength >= 10) pts += 1;
    if (pwLength >= 14) pts += 1;
    if (pwLength >= 20) pts += 1;

    // Points for variety
    if (hasUpper) pts += 1;
    if (hasLower) pts += 1;
    if (hasNums) pts += 1;
    if (hasSpecial) pts += 2;

    // Short passwords can't be "Very Strong"
    if (pwLength < 10 && pts > 5) pts = 5;

    if (pts < 4) return 'Weak';
    if (pts < 6) return 'Moderate';
    if (pts < 8) return 'Strong';
    return 'Very Strong';
  }

  Color _getStrengthColor() {
    final strength = _getStrengthText();

    switch (strength) {
      case 'Weak':
        return Colors.redAccent;
      case 'Moderate':
        return Colors.orangeAccent;
      case 'Strong':
        return Colors.lightGreen;
      case 'Very Strong':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStrength() {
    final strength = _getStrengthText();
    final color = _getStrengthColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Strength: ',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            Text(
              strength,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            if (_easterEggUnlocked && strength == 'Very Strong')
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.star, size: 16, color: Colors.amber),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:
                strength == 'None'
                    ? 0
                    : strength == 'Weak'
                    ? 0.25
                    : strength == 'Moderate'
                    ? 0.5
                    : strength == 'Strong'
                    ? 0.75
                    : 1.0,
            color: color,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Password Generator',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.7, 1.0],
              colors: [
                colors.surface,
                colors.surface.withOpacity(0.9),
                colors.surfaceContainerHighest.withOpacity(0.9),
              ],
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Password display card
                Card(
                  elevation: 0,
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colors.outlineVariant, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.key, color: colors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Your Password',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Password display with animation
                        ScaleTransition(
                          scale: animation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colors.primary.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    currentPass.isEmpty
                                        ? 'No password generated'
                                        : currentPass,
                                    style: TextStyle(
                                      fontFamily: 'Consolas, monospace',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurface,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),

                                if (currentPass.isNotEmpty)
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _copyPassword,
                                      borderRadius: BorderRadius.circular(50),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.copy_rounded,
                                          color: colors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Password strength indicator
                        _buildStrength(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Password length section
                Text(
                  'Password Length',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '8',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$pwLength characters',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),

                    Text(
                      '32',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.primary,
                    inactiveTrackColor: colors.surfaceContainerHighest,
                    thumbColor: colors.primary,
                    overlayColor: colors.primary.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                      elevation: 2,
                    ),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: pwLength.toDouble(),
                    min: 8,
                    max: 32,
                    divisions: 24,
                    onChanged: (value) {
                      setState(() {
                        pwLength = value.toInt();
                      });
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // Character types section
                Text(
                  'Character Types',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.outlineVariant, width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildOption(
                        title: 'Uppercase Letters (A-Z)',
                        icon: Icons.text_fields,
                        value: hasUpper,
                        onChanged: (val) => setState(() => hasUpper = val),
                        isFirst: true,
                      ),
                      _buildOption(
                        title: 'Lowercase Letters (a-z)',
                        icon: Icons.text_format,
                        value: hasLower,
                        onChanged: (val) => setState(() => hasLower = val),
                      ),
                      _buildOption(
                        title: 'Numbers (0-9)',
                        icon: Icons.numbers,
                        value: hasNums,
                        onChanged: (val) => setState(() => hasNums = val),
                      ),
                      _buildOption(
                        title: 'Special Characters (!@#\$%^&*)',
                        icon: Icons.star,
                        value: hasSpecial,
                        onChanged: (val) => setState(() => hasSpecial = val),
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Generate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _hasAnyCharTypes() ? _makeNewPassword : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: colors.surfaceContainerHighest,
                      disabledForegroundColor: colors.onSurfaceVariant,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 20),
                        const SizedBox(width: 10),
                        const Text(
                          'Generate Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildOption({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              !isLast
                  ? BorderSide(color: colors.outlineVariant, width: 0.5)
                  : BorderSide.none,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14.5, color: colors.onSurface),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
