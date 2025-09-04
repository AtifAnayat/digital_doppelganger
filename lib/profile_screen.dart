import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'models/daily_task_model.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;

  ProfileScreen({required this.userName});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  List<DailyData> _allData = [];
  Map<String, dynamic> _stats = {};
  late AnimationController _statsController;
  late Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProfileData();
  }

  void _setupAnimations() {
    _statsController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _statsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOutCubic),
    );
    _statsController.forward();
  }

  @override
  void dispose() {
    _statsController.dispose();
    super.dispose();
  }

  void _loadProfileData() async {
    List<DailyData> data = await DataManager.getAllData();
    setState(() {
      _allData = data;
      _calculateStats();
    });
  }

  void _calculateStats() {
    if (_allData.isEmpty) return;

    int totalWakeUpMinutes = 0;
    int totalSleepMinutes = 0;
    int totalScreenTime = 0;
    Map<String, int> moodCount = {};

    for (DailyData data in _allData) {
      List<String> wakeUpParts = data.wakeUpTime.split(':');
      totalWakeUpMinutes +=
          (int.parse(wakeUpParts[0]) * 60) + int.parse(wakeUpParts[1]);
      List<String> sleepParts = data.sleepTime.split(':');
      totalSleepMinutes +=
          (int.parse(sleepParts[0]) * 60) + int.parse(sleepParts[1]);
      totalScreenTime += data.screenTimeHours;
      moodCount[data.mood] = (moodCount[data.mood] ?? 0) + 1;
    }

    int avgWakeUpMinutes = totalWakeUpMinutes ~/ _allData.length;
    int avgSleepMinutes = totalSleepMinutes ~/ _allData.length;
    String avgWakeUpTime = _convertTo12Hour(avgWakeUpMinutes);
    String avgSleepTime = _convertTo12Hour(avgSleepMinutes);
    String mostFrequentMood = moodCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    _stats = {
      'avgWakeUpTime': avgWakeUpTime,
      'avgSleepTime': avgSleepTime,
      'avgScreenTime': (totalScreenTime / _allData.length).toStringAsFixed(1),
      'mostFrequentMood': mostFrequentMood,
      'totalEntries': _allData.length,
    };
  }

  String _convertTo12Hour(int totalMinutes) {
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    String period = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12;
    if (hours == 0) hours = 12;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period";
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

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color gradientStart,
    required Color gradientEnd,
    int index = 0,
  }) {
    return AnimatedBuilder(
      animation: _statsAnimation,
      builder: (context, child) {
        double delay = index * 0.15;
        double animationValue = (_statsAnimation.value - delay).clamp(0.0, 1.0);
        return Opacity(
          opacity: animationValue,
          child: Transform.scale(
            scale: 0.9 + (0.1 * animationValue),
            child: _buildNeuMorphicCard(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    SizedBox(height: 12),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            color: Color(0xFF9CA3AF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // App Bar
                  Row(
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
                            'Analytics',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 50),
                    ],
                  ),
                  SizedBox(height: 30),
                  // Profile Header
                  _buildNeuMorphicCard(
                    child: Padding(
                      padding: EdgeInsets.all(25),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
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
                            child: Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedBot,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            '${widget.userName}\'s Digital Twin',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Analyzing patterns & behaviors',
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
                  // Empty State
                  if (_allData.isEmpty)
                    _buildNeuMorphicCard(
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFFA726),
                                    Color(0xFFFF8F00),
                                  ],
                                ),
                              ),
                              child: Icon(
                                HugeIcons.strokeRoundedNext,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'No Analytics Yet!',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Start syncing your daily routine to unlock powerful insights about your digital twin.',
                              style: GoogleFonts.inter(
                                color: Color(0xFF9CA3AF),
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Digital Patterns Card (Stats)
                    _buildNeuMorphicCard(
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
                                      colors: [
                                        Color(0xFF00D4AA),
                                        Color(0xFF00A693),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    HugeIcons.strokeRoundedAnalytics01,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 15),
                                Text(
                                  'Your Digital Patterns',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.85,
                              clipBehavior: Clip.antiAlias,
                              children: [
                                _statCard(
                                  label: 'Avg Wake Up',
                                  value: _stats['avgWakeUpTime'] ?? '--:--',
                                  icon: HugeIcons.strokeRoundedSun01,
                                  gradientStart: Color(0xFFF59E0B),
                                  gradientEnd: Color(0xFFFFA726),
                                  index: 0,
                                ),
                                _statCard(
                                  label: 'Avg Sleep',
                                  value: _stats['avgSleepTime'] ?? '--:--',
                                  icon: HugeIcons.strokeRoundedMoon02,
                                  gradientStart: Color(0xFF8B5CF6),
                                  gradientEnd: Color(0xFF6366F1),
                                  index: 1,
                                ),
                                _statCard(
                                  label: 'Screen Time',
                                  value:
                                      '${_stats['avgScreenTime'] ?? '0'} hrs',
                                  icon: HugeIcons.strokeRoundedAiPhone01,
                                  gradientStart: Color(0xFF00D4AA),
                                  gradientEnd: Color(0xFF00A693),
                                  index: 2,
                                ),
                                _statCard(
                                  label: 'Dominant Mood',
                                  value:
                                      _stats['mostFrequentMood'] ?? 'Unknown',
                                  icon: HugeIcons.strokeRoundedSmile,
                                  gradientStart: Color(0xFF6C63FF),
                                  gradientEnd: Color(0xFF3F3D56),
                                  index: 3,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // Recent Activity
                    _buildNeuMorphicCard(
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
                                      colors: [
                                        Color(0xFF6C63FF),
                                        Color(0xFF3F3D56),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    HugeIcons.strokeRoundedWorkHistory,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 15),
                                Text(
                                  'Recent Sync History',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            ...(_allData.reversed
                                .take(5)
                                .map(
                                  (data) => Container(
                                    margin: EdgeInsets.only(bottom: 15),
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: Color(0xFF3F3D56).withOpacity(0.5),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Color(0xFF00D4AA),
                                                Color(0xFF00A693),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data.date,
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                'Wake: ${_convertTo12Hour((int.parse(data.wakeUpTime.split(':')[0]) * 60) + int.parse(data.wakeUpTime.split(':')[1]))} • '
                                                'Sleep: ${_convertTo12Hour((int.parse(data.sleepTime.split(':')[0]) * 60) + int.parse(data.sleepTime.split(':')[1]))} • '
                                                'Screen: ${data.screenTimeHours}h • ${data.mood}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // AI Insights
                    _buildNeuMorphicCard(
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
                                      colors: [
                                        Color(0xFFF59E0B),
                                        Color(0xFFFFA726),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    HugeIcons.strokeRoundedBulbCharging,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 15),
                                Text(
                                  'AI Personality Insights',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            ..._generatePersonalityInsights().map(
                              (insight) => Container(
                                margin: EdgeInsets.only(bottom: 15),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: Color(0xFF3F3D56).withOpacity(0.5),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: EdgeInsets.only(
                                        top: 8,
                                        right: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFF59E0B),
                                            Color(0xFFFFA726),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        insight,
                                        style: GoogleFonts.inter(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
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
                  ],
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _generatePersonalityInsights() {
    if (_allData.isEmpty) return ['Start syncing to unlock insights!'];

    List<String> insights = [];
    int avgWakeUpHour =
        _allData
            .map((d) => int.parse(d.wakeUpTime.split(':')[0]))
            .reduce((a, b) => a + b) ~/
        _allData.length;

    if (avgWakeUpHour < 7) {
      insights.add(
        "🐦 You're a natural early bird! Your morning discipline sets you apart from 80% of people. This habit is strongly linked to higher productivity and life satisfaction.",
      );
    } else if (avgWakeUpHour > 9) {
      insights.add(
        "🦉 You embrace the night owl lifestyle! Your brain likely peaks in creativity during evening hours. Many successful entrepreneurs share this pattern.",
      );
    } else {
      insights.add(
        "⚖️ You maintain perfect sleep balance! Your consistent 7-9 AM wake-up aligns with optimal circadian rhythms and shows excellent self-regulation.",
      );
    }

    double avgScreenTime =
        _allData.map((d) => d.screenTimeHours).reduce((a, b) => a + b) /
        _allData.length;

    if (avgScreenTime > 8) {
      insights.add(
        "📱 You're highly connected to the digital world! While this shows tech fluency, consider the 'digital sunset' technique - reducing screens 2 hours before sleep for better rest quality.",
      );
    } else if (avgScreenTime < 4) {
      insights.add(
        "🌿 You maintain remarkable digital discipline! Your low screen time indicates strong focus abilities and real-world engagement. This is becoming increasingly rare and valuable.",
      );
    } else {
      insights.add(
        "⚡ You've mastered healthy tech-life balance! Your 4-8 hour daily screen time hits the sweet spot - enough for productivity without digital overwhelm.",
      );
    }

    Map<String, int> moodCount = {};
    for (var data in _allData) {
      moodCount[data.mood] = (moodCount[data.mood] ?? 0) + 1;
    }

    String dominantMood = moodCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    switch (dominantMood.toLowerCase()) {
      case 'happy':
        insights.add(
          "☀️ Your happiness dominates your emotional landscape! This positive default state is your superpower - research shows happy people live 7-10 years longer and achieve more success.",
        );
        break;
      case 'tired':
        insights.add(
          "💪 You consistently push your limits! While admirable, remember that rest isn't weakness - it's strategic recovery. Consider power naps or meditation breaks.",
        );
        break;
      case 'excited':
        insights.add(
          "🎉 Your enthusiasm is infectious! This high-energy emotional state drives innovation and attracts opportunities. Channel this excitement into long-term projects.",
        );
        break;
      case 'neutral':
        insights.add(
          "🧘 You maintain emotional equilibrium! This balanced state shows strong emotional intelligence and resilience. You likely handle stress better than most.",
        );
        break;
      default:
        insights.add(
          "🎭 You experience rich emotional diversity! This emotional range indicates deep self-awareness and empathy - traits of natural leaders and creatives.",
        );
    }

    if (_allData.length > 3) {
      List<int> wakeUpHours = _allData
          .map((d) => int.parse(d.wakeUpTime.split(':')[0]))
          .toList();
      int maxWake = wakeUpHours.reduce((a, b) => a > b ? a : b);
      int minWake = wakeUpHours.reduce((a, b) => a < b ? a : b);

      if (maxWake - minWake <= 2) {
        insights.add(
          "🎯 Your routine consistency is extraordinary! Less than 2-hour variation shows elite-level self-discipline. This predictability optimizes your biological systems.",
        );
      } else {
        insights.add(
          "🌊 You adapt fluidly to life's rhythms! Your flexible schedule shows resilience and the ability to thrive in changing environments - a crucial 21st-century skill.",
        );
      }
    }

    if (_allData.length >= 7) {
      insights.add(
        "🔥 You've maintained a ${_allData.length}-day tracking streak! This consistency demonstrates commitment to self-improvement and data-driven living.",
      );
    }

    return insights;
  }
}
