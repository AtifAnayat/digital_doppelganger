import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:toastification/toastification.dart';
import 'models/daily_task_model.dart';

class DailyLogScreen extends StatefulWidget {
  @override
  _DailyLogScreenState createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  TimeOfDay _wakeUpTime = TimeOfDay.now();
  TimeOfDay _sleepTime = TimeOfDay.now();
  int _screenTimeHours = 1;
  String _selectedMood = 'Happy';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<String> _moods = [
    'Happy',
    'Sad',
    'Angry',
    'Excited',
    'Tired',
    'Neutral',
  ];
  final Map<String, String> _moodEmojis = {
    'Happy': '😊',
    'Sad': '😔',
    'Angry': '😠',
    'Excited': '🤩',
    'Tired': '😴',
    'Neutral': '😐',
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadTodayData();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _loadTodayData() async {
    String today = DateTime.now().toString().split(' ')[0];
    DailyData? todayData = await DataManager.getDataForDate(today);

    if (todayData != null) {
      setState(() {
        List<String> wakeUpParts = todayData.wakeUpTime.split(':');
        _wakeUpTime = TimeOfDay(
          hour: int.parse(wakeUpParts[0]),
          minute: int.parse(wakeUpParts[1]),
        );

        List<String> sleepParts = todayData.sleepTime.split(':');
        _sleepTime = TimeOfDay(
          hour: int.parse(sleepParts[0]),
          minute: int.parse(sleepParts[1]),
        );

        _screenTimeHours = todayData.screenTimeHours;
        _selectedMood = todayData.mood;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isWakeUp) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isWakeUp ? _wakeUpTime : _sleepTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              onPrimary: Colors.white,
              surface: Color(0xFF2A2D3A),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFF00D4AA)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isWakeUp)
          _wakeUpTime = picked;
        else
          _sleepTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return "$hour:$minute $period";
  }

  void _saveDailyData() async {
    if (_formKey.currentState!.validate()) {
      String today = DateTime.now().toString().split(' ')[0];

      DailyData dailyData = DailyData(
        date: today,
        wakeUpTime:
            "${_wakeUpTime.hour.toString().padLeft(2, '0')}:${_wakeUpTime.minute.toString().padLeft(2, '0')}",
        sleepTime:
            "${_sleepTime.hour.toString().padLeft(2, '0')}:${_sleepTime.minute.toString().padLeft(2, '0')}",
        screenTimeHours: _screenTimeHours,
        mood: _selectedMood,
      );

      await DataManager.saveDailyData(dailyData);

      CustomToast.show(
        context: context,
        title: 'Sync Successful',
        description: 'Daily sync completed! Your twin is learning...',
        type: ToastificationType.success,
        autoCloseDuration: Duration(seconds: 3),
        alignment: Alignment.bottomCenter,
      );

      Navigator.pop(context);
    }
  }

  Widget _buildNeuMorphicCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Color(0xFF2A2D3A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: Offset(-8, -8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 30,
            offset: Offset(8, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: child,
    );
  }

  Widget _buildTimeCard(
    String title,
    IconData icon,
    Color gradientStart,
    Color gradientEnd,
    String time,
    VoidCallback onTap,
  ) {
    return _buildNeuMorphicCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [gradientStart, gradientEnd],
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        color: Color(0xFF9CA3AF),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                HugeIcons.strokeRoundedClock01,
                color: Color(0xFF6C63FF),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1D29),
      body: Stack(
        children: [
          // Animated Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1D29),
                  Color(0xFF2A2D3A),
                  Color(0xFF1A1D29),
                ],
              ),
            ),
          ),
          // Floating Orbs
          Positioned(
            top: 50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF6C63FF).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF00D4AA).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Custom App Bar
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              HugeIcons.strokeRoundedArrowLeft02,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Daily Sync',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 50), // Balance the back button
                      ],
                    ),
                  ),
                  // Form Content
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Header Card
                              _buildNeuMorphicCard(
                                child: Padding(
                                  padding: EdgeInsets.all(25),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF6C63FF),
                                              Color(0xFF00D4AA),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: HugeIcon(
                                            icon: HugeIcons.strokeRoundedBot,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        'How was your day?',
                                        style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        DateTime.now().toString().split(' ')[0],
                                        style: GoogleFonts.inter(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 30),
                              // Time Selection Cards
                              _buildTimeCard(
                                'Wake Up Time',
                                HugeIcons.strokeRoundedSun01,
                                Color(0xFFF59E0B),
                                Color(0xFFFFA726),
                                _formatTime(_wakeUpTime),
                                () => _selectTime(context, true),
                              ),
                              SizedBox(height: 20),
                              _buildTimeCard(
                                'Sleep Time',
                                HugeIcons.strokeRoundedMoon02,
                                Color(0xFF8B5CF6),
                                Color(0xFF6366F1),
                                _formatTime(_sleepTime),
                                () => _selectTime(context, false),
                              ),
                              SizedBox(height: 30),
                              // Screen Time Card
                              _buildNeuMorphicCard(
                                child: Padding(
                                  padding: EdgeInsets.all(25),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF00D4AA),
                                                  Color(0xFF00A693),
                                                ],
                                              ),
                                            ),
                                            child: Icon(
                                              HugeIcons.strokeRoundedAiPhone01,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          SizedBox(width: 15),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Screen Time',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                '$_screenTimeHours hours',
                                                style: GoogleFonts.inter(
                                                  color: Color(0xFF9CA3AF),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 20),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: Color(0xFF6C63FF),
                                          inactiveTrackColor: Color(
                                            0xFF6C63FF,
                                          ).withOpacity(0.3),
                                          thumbColor: Colors.white,
                                          overlayColor: Color(
                                            0xFF6C63FF,
                                          ).withOpacity(0.2),
                                          thumbShape: RoundSliderThumbShape(
                                            enabledThumbRadius: 12,
                                          ),
                                          trackHeight: 6,
                                        ),
                                        child: Slider(
                                          value: _screenTimeHours.toDouble(),
                                          min: 1,
                                          max: 16,
                                          divisions: 15,
                                          label: '$_screenTimeHours hours',
                                          onChanged: (value) {
                                            setState(() {
                                              _screenTimeHours = value.round();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 30),
                              // Mood Selection
                              _buildNeuMorphicCard(
                                child: Padding(
                                  padding: EdgeInsets.all(25),
                                  child: Column(
                                    children: [
                                      Text(
                                        'How are you feeling?',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        alignment: WrapAlignment.center,
                                        children: _moods.map((mood) {
                                          bool isSelected =
                                              mood == _selectedMood;
                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedMood = mood;
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                                gradient: isSelected
                                                    ? LinearGradient(
                                                        colors: [
                                                          Color(0xFF6C63FF),
                                                          Color(0xFF00D4AA),
                                                        ],
                                                      )
                                                    : null,
                                                color: isSelected
                                                    ? null
                                                    : Color(
                                                        0xFF3F3D56,
                                                      ).withOpacity(0.5),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.white
                                                            .withOpacity(0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _moodEmojis[mood]!,
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    mood,
                                                    style: GoogleFonts.inter(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Color(0xFF9CA3AF),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Save Button
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C63FF).withOpacity(0.4),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveDailyData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              HugeIcons.strokeRoundedAdd01,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Sync with Doppelganger',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
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
        ],
      ),
    );
  }
}

// CustomToast class included in the same file for completeness
class CustomToast {
  static void show({
    required BuildContext context,
    required String title,
    required String description,
    required ToastificationType type,
    Duration autoCloseDuration = const Duration(seconds: 5),
    Alignment alignment = Alignment.bottomCenter,
  }) {
    toastification.showCustom(
      context: context,
      autoCloseDuration: autoCloseDuration,
      alignment: alignment,
      dismissDirection: DismissDirection.horizontal,
      animationBuilder: (context, animation, alignment, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      builder: (BuildContext context, ToastificationItem holder) {
        return _buildCustomToast(context, holder, title, description, type);
      },
    );
  }

  static Widget _buildCustomToast(
    BuildContext context,
    ToastificationItem holder,
    String title,
    String description,
    ToastificationType type,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, primaryColor) = _getToastAttributes(type);

    return GestureDetector(
      onTapDown: (_) => holder.pause(),
      onTapUp: (_) => holder.start(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        width: 300,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => toastification.dismissById(holder.id),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (IconData, Color) _getToastAttributes(ToastificationType type) {
    switch (type) {
      case ToastificationType.success:
        return (Icons.check_circle_outline, Color(0xFF00D4AA));
      case ToastificationType.error:
        return (Icons.error_outline, Colors.red);
      case ToastificationType.warning:
        return (Icons.warning_amber_rounded, Colors.yellow[800]!);
      case ToastificationType.info:
        return (Icons.info_outline, Colors.blue);
      default:
        return (Icons.info_outline, Colors.grey);
    }
  }
}
