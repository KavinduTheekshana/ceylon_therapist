import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'api_service.dart';
import 'package:audioplayers/audioplayers.dart';

class TreatmentSessionScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const TreatmentSessionScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<TreatmentSessionScreen> createState() => _TreatmentSessionScreenState();
}

class _TreatmentSessionScreenState extends State<TreatmentSessionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _timer;
  late int _totalSeconds;
  late int _remainingSeconds;
  bool _isTimerRunning = false;
  bool _isTimerStarted = false;
  bool _isCompleted = false;
  
  // Add these for background timer tracking
  DateTime? _timerStartTime;
  DateTime? _pauseTime;
  
  // Audio player for completion sound
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Modern color scheme
  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _surfaceColor = Color(0xFFFAFBFF);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _successColor = Color(0xFF059669);
  static const Color _warningColor = Color(0xFFD97706);
  static const Color _errorColor = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Initialize timer with service duration
    final duration = widget.appointment['service']['duration'] ?? 30;
    _totalSeconds = duration * 60; // Convert minutes to seconds
    _remainingSeconds = _totalSeconds;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is going to background or screen is turning off
        if (_isTimerRunning) {
          _pauseTime = DateTime.now();
          print('App paused at: $_pauseTime');
        }
        break;
        
      case AppLifecycleState.resumed:
        // App is coming back to foreground
        if (_isTimerRunning && _pauseTime != null && _timerStartTime != null) {
          _resumeFromBackground();
        }
        break;
        
      case AppLifecycleState.inactive:
        // Handle inactive state (like during phone calls)
        break;
    }
  }

  void _resumeFromBackground() {
    if (_pauseTime == null || _timerStartTime == null) return;
    
    final now = DateTime.now();
    final backgroundDuration = now.difference(_pauseTime!);
    final totalElapsed = now.difference(_timerStartTime!);
    
    print('Resumed from background. Background duration: ${backgroundDuration.inSeconds}s');
    print('Total elapsed since start: ${totalElapsed.inSeconds}s');
    
    // Calculate new remaining time based on actual elapsed time
    final newRemainingSeconds = _totalSeconds - totalElapsed.inSeconds;
    
    setState(() {
      if (newRemainingSeconds <= 0) {
        // Timer should have completed while in background
        _remainingSeconds = 0;
        _completeSession();
      } else {
        _remainingSeconds = newRemainingSeconds;
      }
    });
    
    _pauseTime = null;
  }

  void _startTimer() {
    if (_isTimerRunning) return;

    setState(() {
      _isTimerRunning = true;
      _isTimerStarted = true;
    });

    // Record the start time for background tracking
    if (_timerStartTime == null) {
      _timerStartTime = DateTime.now();
    } else {
      // If resuming, adjust start time based on elapsed time
      final elapsed = _totalSeconds - _remainingSeconds;
      _timerStartTime = DateTime.now().subtract(Duration(seconds: elapsed));
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          
          // Play warning sounds at specific intervals
          if (_remainingSeconds == 60) {
            // 1 minute warning
            HapticFeedback.mediumImpact();
            SystemSound.play(SystemSoundType.alert);
          } else if (_remainingSeconds == 30) {
            // 30 seconds warning
            HapticFeedback.mediumImpact();
            SystemSound.play(SystemSoundType.alert);
          } else if (_remainingSeconds <= 10 && _remainingSeconds > 0) {
            // Final 10 seconds countdown
            HapticFeedback.lightImpact();
            SystemSound.play(SystemSoundType.alert);
          }
        } else {
          _completeSession();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pauseTime = DateTime.now();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resumeTimer() {
    if (_remainingSeconds > 0) {
      _pauseTime = null;
      _startTimer();
    }
  }

  void _completeSession() async {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _isCompleted = true;
      _remainingSeconds = 0;
    });

    // Play completion sound and vibrate first
    await _playCompletionAlert();

    // Then show completion dialog (removed duplicate call)
    _showCompletionDialog();
  }

  Future<void> _playCompletionAlert() async {
    try {
      // Multiple alert patterns for better notification
      print('Playing completion alert...');
      
      // First alert - immediate
      SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.heavyImpact();
      
      // Create a sequence of alerts
      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(milliseconds: 400));
        SystemSound.play(SystemSoundType.alert);
        await HapticFeedback.mediumImpact();
      }
      
      // Final strong vibration
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
      
      print('Completion alert finished');
      
    } catch (e) {
      // Enhanced fallback with multiple attempts
      print('Alert playback failed: $e');
      try {
        // Try different system sounds as fallback
        SystemSound.play(SystemSoundType.click);
        await Future.delayed(const Duration(milliseconds: 100));
        SystemSound.play(SystemSoundType.click);
        await HapticFeedback.heavyImpact();
      } catch (e2) {
        print('Fallback alert also failed: $e2');
      }
    }
  }

  // Separate method for manual completion (Complete Now button)
  void _manualCompleteSession() async {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _isCompleted = true;
      _remainingSeconds = 0;
    });

    // Play completion sound for manual completion too
    await _playCompletionAlert();
    
    // Show completion dialog
    _showCompletionDialog();
  }

  Future<void> _updateBookingStatus(String status, {String? notes}) async {
    try {
      final bookingId = widget.appointment['id'];
      if (bookingId == null) {
        _showErrorDialog('Invalid booking ID');
        return;
      }

      final result = await ApiService.updateBookingStatus(
        bookingId: bookingId,
        status: status,
        notes: notes,
      );

      if (!result['success']) {
        _showErrorDialog(result['message'] ?? 'Failed to update booking status');
      }
    } catch (e) {
      _showErrorDialog('Network error: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: _errorColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Error',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(color: _textSecondary),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: _errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _cancelSession() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cancel Session',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          content: const Text(
            'Are you sure you want to cancel this treatment session? This will mark the booking as cancelled.',
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: _textSecondary),
              child: const Text('Continue Session'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    );
                  },
                );

                // Update booking status to cancelled
                await _updateBookingStatus('cancelled', notes: 'Session cancelled by therapist');
                
                // Close loading dialog
                if (mounted) Navigator.of(context).pop();
                
                // Go back to appointments
                if (mounted) Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: _errorColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Session'),
            ),
          ],
        );
      },
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isConfirming = false;
            final TextEditingController notesController = TextEditingController(
              text: 'Session completed and confirmed by therapist',
            );
            
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: _successColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Session Complete!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isConfirming ? null : () {
                      Navigator.of(context).pop(); // Just close dialog
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _textSecondary,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _borderColor.withOpacity(0.5),
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Treatment session for ${widget.appointment['customer_name']} has been completed successfully.',
                      style: const TextStyle(color: _textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Service: ${widget.appointment['service']['title']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Duration: ${widget.appointment['service']['duration']} minutes',
                            style: const TextStyle(
                              fontSize: 14,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Session Notes section (always visible)
                    const Text(
                      'Session Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: notesController,
                        enabled: !isConfirming,
                        maxLines: 3,
                        maxLength: 250,
                        decoration: InputDecoration(
                          hintText: 'Edit the session notes if needed...',
                          hintStyle: TextStyle(
                            color: _textSecondary.withOpacity(0.7),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(12),
                          counterStyle: const TextStyle(fontSize: 11),
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    const Text(
                      'Press "Confirm" to update the booking status in the system.',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: isConfirming ? null : () async {
                    setState(() {
                      isConfirming = true;
                    });

                    try {
                      // Call API to update booking status
                      final bookingId = widget.appointment['id'];
                      if (bookingId == null) {
                        throw Exception('Invalid booking ID');
                      }

                      // Use the notes from the text field (will have default text or user's edits)
                      final finalNotes = notesController.text.trim().isNotEmpty 
                          ? notesController.text.trim() 
                          : null;

                      final result = await ApiService.updateBookingStatus(
                        bookingId: bookingId,
                        status: 'completed',
                        notes: finalNotes,
                      );

                      if (result['success']) {
                        // Success - close dialog and go back
                        if (mounted) {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context).pop(); // Go back to appointments
                          
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Session completed and booking updated successfully'),
                              backgroundColor: _successColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } else {
                        // Show error
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Failed to update booking'),
                              backgroundColor: _errorColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      // Show error
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString()}'),
                            backgroundColor: _errorColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          isConfirming = false;
                        });
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _successColor,
                    foregroundColor: Colors.white,
                  ),
                  child: isConfirming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    if (_totalSeconds == 0) return 0.0;
    return (_totalSeconds - _remainingSeconds) / _totalSeconds;
  }

  Color _getTimerColor() {
    final progress = _getProgress();
    if (progress < 0.5) return _successColor;
    if (progress < 0.8) return _warningColor;
    return _errorColor;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final safeAreaHeight = screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom;
    
    // Responsive padding and sizing
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isLargeScreen = screenHeight > 800;
    
    final horizontalPadding = screenWidth < 360 ? 16.0 : 20.0;
    final verticalSpacing = isVerySmallScreen ? 12.0 : isSmallScreen ? 16.0 : 24.0;
    
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        title: Text(
          'Treatment Session',
          style: TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        elevation: 0,
        surfaceTintColor: _cardColor,
        shadowColor: Colors.black.withOpacity(0.1),
        scrolledUnderElevation: 1,
        leading: IconButton(
          onPressed: () {
            if (_isTimerRunning) {
              _pauseTimer();
            }
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isSmallScreen ? 12.0 : 16.0,
              ),
              child: Column(
                children: [
                  // Patient Information Card
                  _buildPatientCard(isSmallScreen),
                  SizedBox(height: verticalSpacing),

                  // Timer Display - Make it flexible
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildTimerDisplay(constraints.maxHeight, isSmallScreen, isVerySmallScreen);
                      },
                    ),
                  ),

                  // Control Buttons - Always visible at bottom
                  SafeArea(
                    top: false,
                    child: _buildControlButtons(isSmallScreen),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: _primaryColor,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.appointment['customer_name'] ?? 'Unknown Patient',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ref: ${widget.appointment['reference'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12.0 : 16.0),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.medical_services_rounded,
                      size: isSmallScreen ? 16 : 18,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.appointment['service']['title'] ?? 'Treatment',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '£${widget.appointment['price'] ?? '0'}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.w700,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8.0 : 12.0),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: isSmallScreen ? 16 : 18,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Duration: ${widget.appointment['service']['duration'] ?? 30} minutes',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(double availableHeight, bool isSmallScreen, bool isVerySmallScreen) {
    // Calculate responsive timer size based on available space
    double timerSize;
    double fontSize;
    double statusFontSize;
    
    if (isVerySmallScreen) {
      timerSize = availableHeight * 0.6;
      timerSize = timerSize.clamp(180.0, 220.0);
      fontSize = 32;
      statusFontSize = 14;
    } else if (isSmallScreen) {
      timerSize = availableHeight * 0.65;
      timerSize = timerSize.clamp(200.0, 240.0);
      fontSize = 38;
      statusFontSize = 15;
    } else {
      timerSize = availableHeight * 0.7;
      timerSize = timerSize.clamp(240.0, 300.0);
      fontSize = 48;
      statusFontSize = 16;
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Add some top padding to center better
          SizedBox(height: availableHeight * 0.05),
          
          // Circular Progress Indicator
          SizedBox(
            width: timerSize,
            height: timerSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                Container(
                  width: timerSize,
                  height: timerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _surfaceColor,
                    border: Border.all(
                      color: _borderColor,
                      width: 2,
                    ),
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: timerSize - 20,
                  height: timerSize - 20,
                  child: CircularProgressIndicator(
                    value: _getProgress(),
                    strokeWidth: isVerySmallScreen ? 8 : isSmallScreen ? 10 : 12,
                    backgroundColor: _borderColor.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(_getTimerColor()),
                  ),
                ),
                // Timer text
                Padding(
                  padding: EdgeInsets.all(timerSize * 0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            color: _getTimerColor(),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      SizedBox(height: isVerySmallScreen ? 4 : 8),
                      Text(
                        _isCompleted
                            ? 'Completed!'
                            : _isTimerRunning
                                ? 'In Progress'
                                : _isTimerStarted
                                    ? 'Paused'
                                    : 'Ready to Start',
                        style: TextStyle(
                          fontSize: statusFontSize,
                          fontWeight: FontWeight.w500,
                          color: _textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 16 : isSmallScreen ? 20 : 32),
          
          // Progress info
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20, 
              vertical: isSmallScreen ? 10 : 12,
            ),
            decoration: BoxDecoration(
              color: _getTimerColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Elapsed: ${_formatTime(_totalSeconds - _remainingSeconds)} / ${_formatTime(_totalSeconds)}',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: _getTimerColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(bool isSmallScreen) {
    final buttonHeight = isSmallScreen ? 48.0 : 56.0;
    final buttonFontSize = isSmallScreen ? 16.0 : 18.0;
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    
    return Column(
      children: [
        if (!_isCompleted) ...[
          // Primary action button
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: FilledButton(
              onPressed: _isTimerRunning ? _pauseTimer : _resumeTimer,
              style: FilledButton.styleFrom(
                backgroundColor: _isTimerRunning ? _warningColor : _successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: iconSize,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _isTimerRunning
                          ? 'Pause Timer'
                          : _isTimerStarted
                              ? 'Resume Timer'
                              : 'Start Timer Now',
                      style: TextStyle(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          // Secondary buttons - Stack vertically on very small screens
          LayoutBuilder(
            builder: (context, constraints) {
              final shouldStack = constraints.maxWidth < 300;
              
              if (shouldStack) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: OutlinedButton(
                        onPressed: _manualCompleteSession,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _successColor,
                          side: const BorderSide(color: _successColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Complete Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: buttonFontSize,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: OutlinedButton(
                        onPressed: _cancelSession,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _errorColor,
                          side: const BorderSide(color: _errorColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: buttonFontSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: _manualCompleteSession,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _successColor,
                            side: const BorderSide(color: _successColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Complete Now',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: buttonFontSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: _cancelSession,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _errorColor,
                            side: const BorderSide(color: _errorColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: buttonFontSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ] else ...[
          // Session completed - only show done button
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: _successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: iconSize),
                  const SizedBox(width: 8),
                  Text(
                    'Session Complete',
                    style: TextStyle(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}