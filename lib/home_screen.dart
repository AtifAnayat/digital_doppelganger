import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'daily_log_screen.dart';
import 'models/daily_task_model.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  HomeScreen({required this.userName});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  DailyData? todayData;
  DailyData? yesterdayData;
  List<DailyData> weeklyData = [];
  List<DailyData> monthlyData = [];
  Map<String, dynamic> stats = {};
  bool isWeeklyView = true;
  bool isLoading = true;

  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  void _setupAnimations() {
    _floatingController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _pulseAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatingController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _loadData() async {
    setState(() {
      isLoading = true;
    });

    List<DailyData> allData = await DataManager.getAllData();
    allData.sort(
      (a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)),
    );

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = now.subtract(Duration(days: 1));
    final yesterdayStr =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final sevenDaysAgo = now.subtract(Duration(days: 6));
    weeklyData = allData.where((d) {
      final dDate = DateTime.parse(d.date);
      return dDate.isAfter(sevenDaysAgo) ||
          dDate.isAtSameMomentAs(sevenDaysAgo);
    }).toList();

    final thirtyDaysAgo = now.subtract(Duration(days: 29));
    monthlyData = allData.where((d) {
      final dDate = DateTime.parse(d.date);
      return dDate.isAfter(thirtyDaysAgo) ||
          dDate.isAtSameMomentAs(thirtyDaysAgo);
    }).toList();

    setState(() {
      try {
        todayData = allData.firstWhere((d) => d.date == todayStr);
      } catch (e) {
        todayData = null;
      }
      try {
        yesterdayData = allData.firstWhere((d) => d.date == yesterdayStr);
      } catch (e) {
        yesterdayData = null;
      }
      isLoading = false;
    });

    _calculateStats(allData);
    _fadeController.forward();
  }

  void _calculateStats(List<DailyData> allData) {
    if (allData.isEmpty) return;

    int totalWakeUpMinutes = 0;
    int totalSleepMinutes = 0;
    int totalScreenTime = 0;
    Map<String, int> moodCount = {};

    for (DailyData data in allData) {
      List<String> wakeUpParts = data.wakeUpTime.split(':');
      totalWakeUpMinutes +=
          (int.parse(wakeUpParts[0]) * 60) + int.parse(wakeUpParts[1]);

      List<String> sleepParts = data.sleepTime.split(':');
      totalSleepMinutes +=
          (int.parse(sleepParts[0]) * 60) + int.parse(sleepParts[1]);

      totalScreenTime += data.screenTimeHours;

      moodCount[data.mood] = (moodCount[data.mood] ?? 0) + 1;
    }

    int avgWakeUpMinutes = totalWakeUpMinutes ~/ allData.length;
    int avgSleepMinutes = totalSleepMinutes ~/ allData.length;

    String avgWakeUpTime = _convertTo12Hour(avgWakeUpMinutes);
    String avgSleepTime = _convertTo12Hour(avgSleepMinutes);

    String mostFrequentMood = moodCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    setState(() {
      stats = {
        'avgWakeUpTime': avgWakeUpTime,
        'avgSleepTime': avgSleepTime,
        'avgScreenTime': (totalScreenTime / allData.length).toStringAsFixed(1),
        'mostFrequentMood': mostFrequentMood,
        'totalEntries': allData.length,
      };
    });
  }

  String _convertTo12Hour(int totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    String period = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    if (hours == 0) hours = 12;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period";
  }

  String _getDoppelgangerEmoji() {
    if (todayData == null) return '🌟';

    switch (todayData!.mood.toLowerCase()) {
      case 'happy':
        return '✨';
      case 'sad':
        return '💙';
      case 'angry':
        return '🔥';
      case 'excited':
        return '⚡';
      case 'tired':
        return '🌙';
      case 'neutral':
        return '🎯';
      default:
        return '🌟';
    }
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Rise & Shine';
    if (hour < 17) return 'Keep Going';
    if (hour < 21) return 'Wind Down';
    return 'Rest Well';
  }

  Widget _buildFloatingAvatar() {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6C63FF),
                        Color(0xFF3F3D56),
                        Color(0xFF00D4AA),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6C63FF).withOpacity(0.4),
                        blurRadius: 60,
                        spreadRadius: 0,
                        offset: Offset(0, 30),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getDoppelgangerEmoji(),
                        style: TextStyle(fontSize: 70),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNeuMorphicCard({required Widget child, Color? customColor}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: customColor ?? Color(0xFF2A2D3A),
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

  Widget _buildMirrorInsightsCard() {
    return _buildNeuMorphicCard(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF00A693)],
                    ),
                  ),
                  child: Icon(
                    HugeIcons.strokeRoundedBulbCharging,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insights',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _getMirrorInsightSubtitle(),
                        style: GoogleFonts.inter(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFF00D4AA).withOpacity(0.2),
                  ),
                  child: Icon(
                    HugeIcons.strokeRoundedTrapezoidLineVertical,
                    size: 20,
                    color: Color(0xFF00D4AA),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6C63FF).withOpacity(0.1),
                    Color(0xFF00D4AA).withOpacity(0.05),
                  ],
                ),
                border: Border.all(
                  color: Color(0xFF6C63FF).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCurrentInsight(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFF00D4AA).withOpacity(0.2),
                        ),
                        child: Icon(
                          HugeIcons.strokeRoundedIdea01,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getActionableAdvice(),
                          style: GoogleFonts.inter(
                            color: Colors.orangeAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMirrorInsightSubtitle() {
    if (todayData == null) return 'Ready to analyze your patterns';

    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning analysis complete';
    if (hour < 18) return 'Midday insights ready';
    return 'Daily reflection processed';
  }

  String _getCurrentInsight() {
    List<String> insights = [];

    if (yesterdayData != null && todayData != null) {
      int todayWakeHour = int.parse(todayData!.wakeUpTime.split(':')[0]);
      int yesterdayWakeHour = int.parse(
        yesterdayData!.wakeUpTime.split(':')[0],
      );

      if (todayWakeHour < yesterdayWakeHour) {
        insights.add(
          "🌅 Excellent! You woke up ${yesterdayWakeHour - todayWakeHour} hour(s) earlier today. Early risers report 23% higher life satisfaction and improved cognitive performance throughout the day.",
        );
      } else if (todayWakeHour > yesterdayWakeHour) {
        insights.add(
          "🛌 You needed extra rest today. Quality sleep is crucial for memory consolidation and emotional regulation. Consider maintaining consistent sleep schedules for optimal circadian health.",
        );
      }

      if (todayData!.screenTimeHours != yesterdayData!.screenTimeHours) {
        int diff = todayData!.screenTimeHours - yesterdayData!.screenTimeHours;
        if (diff > 0) {
          insights.add(
            "📱 Screen time increased by ${diff} hour(s). The average person checks their phone 96 times daily. Try the digital wellness approach: mindful usage with intentional breaks.",
          );
        } else {
          insights.add(
            "🌱 Fantastic digital discipline! Reducing screen time by ${diff.abs()} hour(s) can improve sleep quality by up to 30% and boost real-world social connections.",
          );
        }
      }
    } else if (todayData != null) {
      int wakeHour = int.parse(todayData!.wakeUpTime.split(':')[0]);
      if (wakeHour < 7) {
        insights.add(
          "⭐ You're in the 5 AM club! Studies show early risers are 33% more proactive and experience less stress. Your morning routine is setting you up for success.",
        );
      } else if (wakeHour > 9) {
        insights.add(
          "🎨 Night owl energy detected! Your brain's peak creativity often happens in the evening. Optimize your schedule around these natural energy waves for maximum productivity.",
        );
      }
    }

    return insights.isNotEmpty
        ? insights.first
        : "🧠 Your digital twin is learning. Each data point helps build a more accurate model of your behavioral patterns and optimization opportunities.";
  }

  String _getActionableAdvice() {
    if (todayData == null)
      return "Start your first sync to unlock personalized insights!";

    if (todayData!.screenTimeHours > 8) {
      return "Try 'digital minimalism' - batch similar tasks to reduce context switching.";
    } else if (todayData!.mood.toLowerCase() == 'tired') {
      return "Consider a 20-minute power nap between 1-3 PM for optimal energy restoration.";
    } else if (todayData!.mood.toLowerCase() == 'happy') {
      return "Happiness amplifier: Share this positive energy with someone special today.";
    }

    return "Consistency is key - maintain your routines to strengthen neural pathways.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1D29),
      body: Stack(
        children: [
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
          Positioned(
            top: 100,
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
            bottom: 200,
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
          SafeArea(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF6C63FF),
                            ),
                            strokeWidth: 4,
                          ),
                        ),
                        SizedBox(height: 30),
                        Text(
                          'Initializing Digital Twin...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Analyzing behavioral patterns',
                          style: GoogleFonts.inter(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: Color(
                                          0xFF6C63FF,
                                        ).withOpacity(0.2),
                                        border: Border.all(
                                          color: Color(
                                            0xFF6C63FF,
                                          ).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        _getGreetingMessage(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Color(0xFF6C63FF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      widget.userName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFF3F3D56),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF6C63FF).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileScreen(
                                          userName: widget.userName,
                                        ),
                                      ),
                                    );
                                    _loadData();
                                  },
                                  icon: Icon(
                                    HugeIcons.strokeRoundedUser02,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 50),
                          _buildFloatingAvatar(),
                          SizedBox(height: 50),
                          _buildNeuMorphicCard(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: todayData != null
                                                    ? Color(0xFF00D4AA)
                                                    : Color(0xFFFFA726),
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              todayData != null
                                                  ? 'SYNCHRONIZED'
                                                  : 'PENDING SYNC',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: todayData != null
                                                    ? Color(0xFF00D4AA)
                                                    : Color(0xFFFFA726),
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          todayData != null
                                              ? 'Digital Twin Active'
                                              : 'Awaiting Daily Input',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          todayData != null
                                              ? 'Your behavioral patterns are being analyzed'
                                              : 'Complete today\'s sync to activate insights',
                                          style: GoogleFonts.inter(
                                            color: Color(0xFF9CA3AF),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: LinearGradient(
                                        colors: todayData != null
                                            ? [
                                                Color(0xFF00D4AA),
                                                Color(0xFF00A693),
                                              ]
                                            : [
                                                Color(0xFFFFA726),
                                                Color(0xFFFF8F00),
                                              ],
                                      ),
                                    ),
                                    child: Icon(
                                      todayData != null
                                          ? HugeIcons.strokeRoundedTick01
                                          : HugeIcons.strokeRoundedNext,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          _buildMirrorInsightsCard(),
                          SizedBox(height: 30),
                          if (weeklyData.isNotEmpty ||
                              monthlyData.isNotEmpty) ...[
                            Container(
                              margin: EdgeInsets.only(bottom: 25),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Color(0xFF2A2D3A),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => setState(
                                            () => isWeeklyView = true,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              gradient: isWeeklyView
                                                  ? LinearGradient(
                                                      colors: [
                                                        Color(0xFF6C63FF),
                                                        Color(0xFF3F3D56),
                                                      ],
                                                    )
                                                  : null,
                                            ),
                                            child: Text(
                                              'Weekly',
                                              style: GoogleFonts.poppins(
                                                color: isWeeklyView
                                                    ? Colors.white
                                                    : Color(0xFF9CA3AF),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(
                                            () => isWeeklyView = false,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              gradient: !isWeeklyView
                                                  ? LinearGradient(
                                                      colors: [
                                                        Color(0xFF6C63FF),
                                                        Color(0xFF3F3D56),
                                                      ],
                                                    )
                                                  : null,
                                            ),
                                            child: Text(
                                              'Monthly',
                                              style: GoogleFonts.poppins(
                                                color: !isWeeklyView
                                                    ? Colors.white
                                                    : Color(0xFF9CA3AF),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SleepGraphCard(
                              data: isWeeklyView ? weeklyData : monthlyData,
                              title: isWeeklyView
                                  ? 'Weekly Sleep Pattern'
                                  : 'Monthly Sleep Pattern',
                              isWeeklyView: isWeeklyView,
                            ),
                            SizedBox(height: 25),
                            ScreenTimeGraphCard(
                              data: isWeeklyView ? weeklyData : monthlyData,
                              title: isWeeklyView
                                  ? 'Weekly Screen Time'
                                  : 'Monthly Screen Time',
                              isWeeklyView: isWeeklyView,
                            ),
                            SizedBox(height: 40),
                          ],
                          SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
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
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DailyLogScreen()),
            );
            _loadData();
          },
          icon: Icon(HugeIcons.strokeRoundedAdd01, size: 24),
          label: Text(
            'Daily Sync',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class SleepGraphCard extends StatelessWidget {
  final List<DailyData> data;
  final String title;
  final bool isWeeklyView;

  SleepGraphCard({
    required this.data,
    required this.title,
    required this.isWeeklyView,
  });

  String _convertTo12Hour(double hour) {
    int totalMinutes = (hour * 60).toInt();
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    String period = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    if (hours == 0) hours = 12;
    return "${hours}:${minutes.toString().padLeft(2, '0')} $period";
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _modernCard(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Color(0xFF6C63FF).withOpacity(0.2),
                ),
                child: Icon(
                  HugeIcons.strokeRoundedBed,
                  size: 40,
                  color: Color(0xFF6C63FF),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Sleep Data Loading...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Start syncing to see patterns',
                style: GoogleFonts.inter(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    List<FlSpot> sleepSpots = [];
    List<FlSpot> wakeSpots = [];
    List<String> labels = [];

    for (int i = 0; i < data.length; i++) {
      final dailyData = data[i];
      final sleepParts = dailyData.sleepTime.split(':');
      final wakeParts = dailyData.wakeUpTime.split(':');

      double sleepHour =
          int.parse(sleepParts[0]) + int.parse(sleepParts[1]) / 60.0;
      double wakeHour =
          int.parse(wakeParts[0]) + int.parse(wakeParts[1]) / 60.0;

      sleepSpots.add(FlSpot(i.toDouble(), sleepHour));
      wakeSpots.add(FlSpot(i.toDouble(), wakeHour));

      labels.add(data[i].date.split('-').last);
    }

    Widget chart = LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: 24,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 4,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Color(0xFF374151).withOpacity(0.5), strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              FlLine(color: Color(0xFF374151).withOpacity(0.3), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 65,
              interval: 4,
              getTitlesWidget: (value, meta) {
                return Text(
                  _convertTo12Hour(value),
                  style: GoogleFonts.inter(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      labels[index],
                      style: GoogleFonts.inter(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Color(0xFF374151), width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: sleepSpots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: Color(0xFF8B5CF6),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 5,
                    color: Color(0xFF8B5CF6),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF8B5CF6).withOpacity(0.2),
                  Color(0xFF8B5CF6).withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: wakeSpots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: Color(0xFFF59E0B),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 5,
                    color: Color(0xFFF59E0B),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF59E0B).withOpacity(0.2),
                  Color(0xFFF59E0B).withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );

    return _modernCard(
      child: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                  ),
                  child: Icon(
                    HugeIcons.strokeRoundedBed,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 15),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              height: 300,
              child: isWeeklyView
                  ? chart
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: max(350, data.length * 50.0),
                        child: chart,
                      ),
                    ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem(
                  'Sleep Time',
                  Color(0xFF8B5CF6),
                  HugeIcons.strokeRoundedMoon01,
                ),
                _legendItem(
                  'Wake Time',
                  Color(0xFFF59E0B),
                  HugeIcons.strokeRoundedSun01,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withOpacity(0.2),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        SizedBox(width: 10),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _modernCard({required Widget child}) {
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
}

class ScreenTimeGraphCard extends StatelessWidget {
  final List<DailyData> data;
  final String title;
  final bool isWeeklyView;

  ScreenTimeGraphCard({
    required this.data,
    required this.title,
    required this.isWeeklyView,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _modernCard(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Color(0xFF00D4AA).withOpacity(0.2),
                ),
                child: Icon(
                  HugeIcons.strokeRoundedAiPhone02,
                  size: 40,
                  color: Color(0xFF00D4AA),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Screen Time Loading...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Tracking digital wellness',
                style: GoogleFonts.inter(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    List<FlSpot> screenTimeSpots = [];
    List<String> labels = [];

    for (int i = 0; i < data.length; i++) {
      final dailyData = data[i];
      screenTimeSpots.add(
        FlSpot(i.toDouble(), dailyData.screenTimeHours.toDouble()),
      );
      labels.add(data[i].date.split('-').last);
    }

    double maxScreen = data
        .map((d) => d.screenTimeHours)
        .fold(0, (a, b) => a > b ? a : b)
        .toDouble();
    double yMax = (maxScreen < 6) ? 8 : (maxScreen + 2);

    Widget chart = LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: yMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 2,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Color(0xFF374151).withOpacity(0.5), strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              FlLine(color: Color(0xFF374151).withOpacity(0.3), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: 2,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: GoogleFonts.inter(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      labels[index],
                      style: GoogleFonts.inter(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Color(0xFF374151), width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: screenTimeSpots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: Color(0xFF00D4AA),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 5,
                    color: Color(0xFF00D4AA),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00D4AA).withOpacity(0.2),
                  Color(0xFF00D4AA).withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );

    return _modernCard(
      child: Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF00A693)],
                    ),
                  ),
                  child: Icon(
                    HugeIcons.strokeRoundedAiPhone01,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 15),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Container(
              height: 260,
              child: isWeeklyView
                  ? chart
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        width: max(350, data.length * 50.0),
                        child: chart,
                      ),
                    ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Color(0xFF00D4AA).withOpacity(0.2),
                  ),
                  child: Icon(
                    HugeIcons.strokeRoundedAnalytics01,
                    color: Color(0xFF00D4AA),
                    size: 16,
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(0xFF00D4AA),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Digital Wellness',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernCard({required Widget child}) {
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
}
