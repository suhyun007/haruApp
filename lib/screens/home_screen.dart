import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/meal_provider.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'meal_screen.dart';
import 'weight_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime _selectedDate = DateTime.now();
  String? _dietMethodName;
  String? _dietMethodDescription;
  DateTime? _dietStartDate;
  bool _isLoadingDietMethod = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    
    userProvider.loadUser('user1');
    mealProvider.loadMeals('user1', _selectedDate);
    
    // 다이어트 방법 조회 (임시로 하드코딩된 userId 사용)
    // 실제로는 온보딩 완료 시 저장된 userId를 사용해야 함
    await _loadDietMethod();
  }
  
  Future<void> _loadDietMethod() async {
    setState(() {
      _isLoadingDietMethod = true;
    });
    
    try {
      // 저장된 User ID 불러오기
      final userId = await StorageService.getSupabaseUserId();
      if (userId != null) {
        final user = await ApiService.getUser(userId);
        debugPrint('사용자 데이터: $user');
        if (user != null && user['dietMethod'] != null && mounted) {
          setState(() {
            _dietMethodName = user['dietMethod']['name'];
            _dietMethodDescription = user['dietMethod']['description'];
            // dietStartDate 파싱
            if (user['dietStartDate'] != null) {
              _dietStartDate = DateTime.parse(user['dietStartDate']);
              debugPrint('다이어트 시작일: $_dietStartDate');
            } else {
              debugPrint('dietStartDate가 null입니다');
              debugPrint('사용자 데이터 키들: ${user.keys.toList()}');
            }
            _isLoadingDietMethod = false;
          });
        } else {
          setState(() {
            _isLoadingDietMethod = false;
          });
        }
      } else {
        setState(() {
          _isLoadingDietMethod = false;
        });
      }
    } catch (e) {
      debugPrint('다이어트 방법 조회 실패: $e');
      setState(() {
        _isLoadingDietMethod = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboard(),
      const MealScreen(),
      const WeightScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home_outlined,
                color: _selectedIndex == 0 ? const Color(0xFF588B79) : const Color(0xFFA9C9B2),
              ),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.restaurant_outlined,
                color: _selectedIndex == 1 ? const Color(0xFF588B79) : const Color(0xFFA9C9B2),
              ),
              label: '식사',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.monitor_weight_outlined,
                color: _selectedIndex == 2 ? const Color(0xFF588B79) : const Color(0xFFA9C9B2),
              ),
              label: '체중',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person_outline,
                color: _selectedIndex == 3 ? const Color(0xFF588B79) : const Color(0xFFA9C9B2),
              ),
              label: '프로필',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF588B79),
          unselectedItemColor: const Color(0xFFA9C9B2),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Consumer2<UserProvider, MealProvider>(
      builder: (context, userProvider, mealProvider, child) {
        final user = userProvider.user;
        final totalCalories = mealProvider.totalCalories;
        final calorieGoal = user?.dailyCalorieGoal ?? 2000;

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(user?.name ?? '사용자'),
              const SizedBox(height: 0),
              _buildProgressCard(user),
              const SizedBox(height: 20),
              _buildDiaryCard(),
              const SizedBox(height: 20),
              _buildChallengeSection(),
              const SizedBox(height: 100), // Bottom navigation space
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 70, 30, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '오늘도 잘 왔어요,\n ${userName} 님 ',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF598C7A),
                        ),
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Image.asset(
                          'assets/icon/smaile.png',
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_dietMethodName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dietMethodName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF598C7A),
                        ),
                      ),
                      if (_dietStartDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '+${DateTime.now().difference(_dietStartDate!).inDays}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF598C7A),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 진행',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressItem(
            Icons.monitor_weight_outlined,
            '체중',
            user?.currentWeight != null ? '${user!.currentWeight.toStringAsFixed(1)}kg' : '51kg',
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            Icons.mood,
            '기분',
            '행복해요', 
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            Icons.water_drop_outlined,
            '물',
            '4/8잔',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE7FBEC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF3DDC97),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
          ),
        ),
      ],
    );
  }

  Widget _buildDiaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 다이어리',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '하루의 마음을 한 줄로 기록해요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 다이어리 기록 기능
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DDC97),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '기록하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 챌린지',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 12),
          // 다이어트 방법 설명 표시
          if (_dietMethodDescription != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE7FBEC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF3DDC97),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF3DDC97),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dietMethodName ?? '다이어트 방법',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3DDC97),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _dietMethodDescription!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _buildChallengeButton(
                  Icons.apple,
                  '식단 균형 맞추기',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildChallengeButton(
                  Icons.self_improvement,
                  '5분 명상하기',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeButton(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE7FBEC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF3DDC97),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF555555),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCard(int consumed, int goal) {
    final remaining = goal - consumed;
    final percentage = (consumed / goal * 100).clamp(0, 100);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘의 칼로리',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE7FBEC)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('섭취', style: TextStyle(color: Color(0xFF555555))),
                    Text(
                      '$consumed kcal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE7FBEC),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('남은 칼로리', style: TextStyle(color: Color(0xFF555555))),
                    Text(
                      '$remaining kcal',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightCard(double current, double target) {
    final remaining = current - target;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '체중 현황',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('현재 체중', style: TextStyle(color: Color(0xFF555555))),
                    Text(
                      '${current.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE7FBEC),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('목표까지', style: TextStyle(color: Color(0xFF555555))),
                    Text(
                      '${remaining.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayMeals(List meals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 식사',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (meals.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  '아직 기록된 식사가 없습니다',
                  style: TextStyle(color: Color(0xFF555555)),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: meals.length,
            itemBuilder: (context, index) {
              final meal = meals[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE7FBEC),
                    child: Text(
                      meal.mealType[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(meal.foodName),
                  subtitle: Text(meal.mealType),
                  trailing: Text(
                    '${meal.calories} kcal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7FBEC),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

