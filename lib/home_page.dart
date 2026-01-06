import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'app_snackbar.dart';
import 'my_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platform = MethodChannel('com.example.screen_time_reminder/service');
  static const permissionChannel = MethodChannel('com.example.screen_time_reminder/permission');

  bool _isServiceRunning = false;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadServiceState();
    await _checkAndRestartIfNeeded();
  }

  Future<void> _checkAndRestartIfNeeded() async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    final shouldBeRunning = prefs.getBool('service_enabled') ?? false;

    if (shouldBeRunning && !_isServiceRunning) {
      await _handleServiceStart();
    }
  }

  Future<void> _loadServiceState() async {
    try {
      final bool? isRunning = await platform.invokeMethod<bool>('checkStatus');
      final prefs = await SharedPreferences.getInstance();
      final savedState = prefs.getBool('service_enabled') ?? false;

      setState(() {
        _isServiceRunning = isRunning ?? savedState;
      });

      if (isRunning != null && isRunning != savedState) {
        await _saveServiceState(isRunning);
      }
    } on PlatformException {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isServiceRunning = prefs.getBool('service_enabled') ?? false;
      });
    }
  }

  Future<void> _saveServiceState(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('service_enabled', enabled);
  }

  Future<void> _handleServiceStart() async {
    setState(() => _isRequestingPermission = true);

    try {
      if (Platform.isAndroid) {
        await _handleAndroidPermissionFlow();
      } else {
        await _startServiceDirectly();
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermission = false);
      }
    }
  }

  Future<void> _handleAndroidPermissionFlow() async {
    try {
      // For Android 13+, request permission directly
      print("Requesting notification permission...");
      final bool? granted = await permissionChannel.invokeMethod<bool>('requestNotificationPermission');

      print("Permission result: $granted");
      final hasPermission = granted ?? false;

      if (hasPermission) {
        print("Permission granted, starting service...");
        await _startServiceDirectly();
      } else {
        // Don't show dialog immediately, let user try again
        AppSnackbar.show(
          context: context, // Pass BuildContext
          message: 'Please allow notifications to start monitoring',
          isError: false,
        );
      }
    } on PlatformException catch (e) {
      AppSnackbar.show(
        context: context,
        message: 'Permission error: ${e.message}',
        isError: true,
      );
    }
  }

  Future<void> _startServiceDirectly() async {
    try {
      await platform.invokeMethod('startService');
      setState(() => _isServiceRunning = true);
      await _saveServiceState(true);

      if (mounted) {
        AppSnackbar.show(
          context: context, // Pass BuildContext
          message: 'Eye care monitoring started!',
          isError: false,
        );
      }
    } on PlatformException catch (e) {
      AppSnackbar.show(
        context: context,
        message: 'Failed to start: ${e.message}',
        isError: true,
      );
    }
  }

  Future<void> _stopService() async {
    try {
      await platform.invokeMethod('stopService');
      setState(() => _isServiceRunning = false);
      await _saveServiceState(false);

      if (mounted) {
        AppSnackbar.show(
          context: context, // Pass BuildContext
          message: 'Eye care monitoring stopped',
          isError: false,
        );
      }
    } on PlatformException catch (e) {
      AppSnackbar.show(
        context: context,
        message: 'Failed to stop: ${e.message}',
        isError: true,
      );
    }
  }

  Future<void> _showPermissionExplanation() async {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
          'Notification permission is required to send eye care reminders.\n\n'
              'You can enable it manually in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ) ?? false;

    if (shouldOpenSettings && mounted) {
      await _openAppSettings();
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await permissionChannel.invokeMethod('openAppSettings');
    } on PlatformException {
      AppSnackbar.show(
        context: context,
        message: 'Cannot open settings',
        isError: true,
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Responsive design helpers
  double _responsiveFontSize(double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseSize * 0.85;
    if (width > 600) return baseSize * 1.2;
    return baseSize;
  }

  double get _padding {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 16.0;
    if (width > 600) return 32.0;
    return 24.0;
  }

  double get _iconSize {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 80.0;
    if (width > 600) return 120.0;
    return 100.0;
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: _iconSize * 1.2,
          height: _iconSize * 1.2,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withAlpha(56),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ImageIcon(
            const AssetImage('assets/icon/app_icon.png'),
            size: _iconSize,
            color: const Color(0xFF2196F3),
          ),
        ),
        SizedBox(height: _iconSize * 0.3),
        Text(
          '20-20-20 Rule',
          style: TextStyle(
            fontSize: _responsiveFontSize(28),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: _iconSize * 0.1),
        Text(
          'For every 20 minutes of screen time,\nlook at something 20 feet away\nfor 20 seconds to reduce eye strain',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _responsiveFontSize(16),
            color: const Color(0xFF7F8C8D),
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    Color backgroundColor;
    Color borderColor;
    String title;
    String subtitle;
    Widget icon;

    if (_isRequestingPermission) {
      backgroundColor = const Color(0xFFFFF8E1);
      borderColor = const Color(0xFFFFC107);
      title = 'Setting Up...';
      subtitle = 'Please wait while we set up monitoring';
      icon = SizedBox(
        width: _iconSize * 0.7,
        height: _iconSize * 0.7,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: const Color(0xFFFFC107),
        ),
      );
    } else if (_isServiceRunning) {
      backgroundColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF4CAF50);
      title = 'Active Monitoring';
      subtitle = 'Notifications will remind you every 20 minutes';
      icon = Icon(
        Icons.check_circle_outlined,
        size: _iconSize * 0.7,
        color: const Color(0xFF4CAF50),
      );
    } else {
      backgroundColor = const Color(0xFFF5F5F5);
      borderColor = const Color(0xFFE0E0E0);
      title = 'Ready to Start';
      subtitle = 'Start monitoring to protect your eyes\nfrom digital eye strain';
      icon = Icon(
        Icons.timer_outlined,
        size: _iconSize * 0.7,
        color: const Color(0xFF9E9E9E),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          icon,
          SizedBox(height: _padding * 0.5),
          Text(
            title,
            style: TextStyle(
              fontSize: _responsiveFontSize(22),
              fontWeight: FontWeight.w700,
              color: _isRequestingPermission
                  ? const Color(0xFFFF8F00)
                  : _isServiceRunning
                  ? const Color(0xFF388E3C)
                  : const Color(0xFF616161),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _padding * 0.3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _responsiveFontSize(14),
              color: _isRequestingPermission
                  ? const Color(0xFFFF8F00)
                  : const Color(0xFF757575),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (_isRequestingPermission) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          minimumSize: Size(double.infinity, _responsiveFontSize(56)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: _responsiveFontSize(20),
              height: _responsiveFontSize(20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: _responsiveFontSize(12)),
            Text(
              'Checking permission...',
              style: TextStyle(
                fontSize: _responsiveFontSize(18),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isServiceRunning ? _stopService : _handleServiceStart,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isServiceRunning
            ? const Color(0xFFF44336)
            : const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 3,
        shadowColor: _isServiceRunning
            ? const Color(0xFFF44336).withOpacity(0.3)
            : const Color(0xFF2196F3).withOpacity(0.3),
        minimumSize: Size(double.infinity, _responsiveFontSize(56)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isServiceRunning
                ? Icons.stop_circle_outlined
                : Icons.play_circle_outlined,
            size: _responsiveFontSize(24),
          ),
          SizedBox(width: _responsiveFontSize(12)),
          Text(
            _isServiceRunning ? 'Stop Monitoring' : 'Start Monitoring',
            style: TextStyle(
              fontSize: _responsiveFontSize(18),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: const Color(0xFFFFC107),
                size: _responsiveFontSize(24),
              ),
              SizedBox(width: _responsiveFontSize(12)),
              Text(
                'Eye Care Tips',
                style: TextStyle(
                  fontSize: _responsiveFontSize(18),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: _padding * 0.75),
          Text(
            '• Blink frequently to moisten eyes\n'
                '• Adjust screen brightness to room light\n'
                '• Maintain proper viewing distance\n'
                '• Use artificial tears if needed',
            style: TextStyle(
              fontSize: _responsiveFontSize(14),
              color: const Color(0xFF616161),
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Eye Care Reminder',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: _responsiveFontSize(18),
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        elevation: 4,
        shadowColor: const Color(0xFF2196F3).withAlpha(77),
      ),
      drawer: const MyDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _padding,
            vertical: _padding * 0.75,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              SizedBox(height: _iconSize * 0.3),
              _buildStatusCard(),
              SizedBox(height: _iconSize * 0.3),
              _buildActionButton(),
              SizedBox(height: _iconSize * 0.3),
              _buildTipsCard(),
            ],
          ),
        ),
      ),
    );
  }
}