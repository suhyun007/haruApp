import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../models/diet_method_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _heightUnit = 'cm'; // 기본값: cm
  String _weightUnit = 'kg'; // 기본값: kg
  String _gender = '여성'; // 기본값: 여성
  int _currentStep = 0; // 0: 기본정보, 1: 다이어트 설정
  
  // 2단계 필드
  final _targetWeightController = TextEditingController();
  String _targetWeightUnit = 'kg';
  String? _selectedDietMethod;
  DateTime _dietStartDate = DateTime.now();
  
  // 다이어트 방법 목록
  List<DietMethodModel> _dietMethods = [];
  bool _isLoadingDietMethods = false;

  @override
  void initState() {
    super.initState();
    _loadDietMethods();
  }
  
  // Supabase에서 다이어트 방법 조회
  Future<void> _loadDietMethods() async {
    setState(() {
      _isLoadingDietMethods = true;
    });
    
    try {
      final methods = await ApiService.getDietMethods();
      setState(() {
        _dietMethods = methods;
        _isLoadingDietMethods = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDietMethods = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다이어트 방법을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    // 1단계 유효성 검사
    if (_formKey.currentState!.validate()) {
      setState(() {
        _currentStep = 1;
      });
    }
  }

  void _goToPreviousStep() {
    setState(() {
      _currentStep = 0;
    });
  }

  Future<void> _submitForm() async {
    // 2단계 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedDietMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('다이어트 방법을 선택해주세요'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // 로딩 표시
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3DDC97),
          ),
        );
      },
    );
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // 사용자 정보 준비
      double heightValue = double.tryParse(_heightController.text) ?? 0.0;
      double weightValue = double.tryParse(_weightController.text) ?? 0.0;
      double targetWeightValue = double.tryParse(_targetWeightController.text) ?? 0.0;
      int ageValue = int.tryParse(_ageController.text) ?? 0;
      
      // gender 변환 (한글 -> 영문)
      String genderValue = _gender == '여성' ? 'female' : 'male';
      
      // API 서버에 사용자 생성
      final result = await ApiService.createUser(
        nickname: _nameController.text,
        age: ageValue,
        gender: genderValue,
        height: heightValue,
        heightUnit: _heightUnit,
        currentWeight: weightValue,
        currentWeightUnit: _weightUnit,
        targetWeight: targetWeightValue,
        targetWeightUnit: _targetWeightUnit,
        dietMethodId: _selectedDietMethod!,
        dietStartDate: _dietStartDate,
        dailyCalorieGoal: 2000, // 기본값
      );
      
      if (result == null) {
        throw Exception('사용자 생성 실패');
      }
      
      // 초기 체중 기록 저장
      await ApiService.createWeightRecord(
        userId: result['id'],
        weight: weightValue,
        weightUnit: _weightUnit,
        date: _dietStartDate,
        memo: '시작 체중',
      );
      
      // 단위 변환 (로컬 저장용 - cm, kg로 통일)
      double heightInCm = heightValue;
      if (_heightUnit == 'inch') {
        heightInCm = heightValue * 2.54;
      }
      
      double weightInKg = weightValue;
      if (_weightUnit == 'lb') {
        weightInKg = weightValue * 0.453592;
      }
      
      // UserProvider에 사용자 생성 (로컬 상태 관리)
      userProvider.createUser(
        id: result['id'], // Supabase에서 받은 ID 사용
        name: _nameController.text,
        age: ageValue,
        height: heightInCm,
        currentWeight: weightInKg,
        targetWeight: targetWeightValue, // targetWeight도 추가
        dailyCalorieGoal: 2000,
        gender: _gender,
        dietMethodName: _dietMethods.firstWhere((m) => m.id == _selectedDietMethod).name,
        dietMethodDescription: _dietMethods.firstWhere((m) => m.id == _selectedDietMethod).description,
      );

      // Supabase User ID 저장
      await StorageService.saveSupabaseUserId(result['id']);
      debugPrint('=== 온보딩 완료 ===');
      debugPrint('Supabase User ID 저장: ${result['id']}');
      
      // 로컬 스토리지에 저장
      if (userProvider.user != null) {
        await StorageService.saveUser(userProvider.user!);
        debugPrint('로컬 스토리지에 사용자 저장 완료: ${userProvider.user!.name}');
      }
      
      // 저장 확인
      final savedComplete = await StorageService.isOnboardingComplete();
      debugPrint('온보딩 완료 플래그: $savedComplete');

      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 메인 화면으로 이동
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // 에러 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류가 발생했습니다: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 로고/제목 영역
                if (_currentStep == 0)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7FBEC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Color(0xFF3DDC97),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'haruFit',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF598C7A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '오늘부터 haruFit으로\n몸과 마음을 건강하게\n시작해보아요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF555555),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                
                if (_currentStep == 0) const SizedBox(height: 20),
                
                // 입력 폼 영역
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _currentStep == 0 
                      ? _buildStep1() // 1단계: 기본 정보
                      : _buildStep2(), // 2단계: 다이어트 설정
                ),
                
                const SizedBox(height: 10),
                
                // 버튼 영역
                _currentStep == 0
                    ? SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _goToNextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3DDC97),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            '다음',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: _goToPreviousStep,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF3DDC97)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  '이전',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3DDC97),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3DDC97),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  '시작하기',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                
                const SizedBox(height: 12),
                
                // 개인정보 안내 문구
                const Text(
                  '입력하신 정보는 맞춤 서비스 제공을 위해서만 안전하게 사용됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20), // 하단 여백 추가
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '성별',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FFFE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _gender = '여성';
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _gender == '여성' 
                          ? const Color(0xFF3DDC97) 
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(11),
                        bottomLeft: Radius.circular(11),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '여성',
                        style: TextStyle(
                          color: _gender == '여성' 
                              ? Colors.white 
                              : const Color(0xFF555555),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _gender = '남성';
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _gender == '남성' 
                          ? const Color(0xFF3DDC97) 
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(11),
                        bottomRight: Radius.circular(11),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '남성',
                        style: TextStyle(
                          color: _gender == '남성' 
                              ? Colors.white 
                              : const Color(0xFF555555),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '몸무게',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '몸무게를 입력해주세요';
                  }
                  if (double.tryParse(value) == null) {
                    return '올바른 몸무게를 입력해주세요';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: '몸무게를 입력해주세요',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.2,
                  ),
                  prefixIcon: const Icon(
                    Icons.monitor_weight,
                    color: Color(0xFF3DDC97),
                    size: 22,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FFFE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3DDC97),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FFFE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _weightUnit = 'kg';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _weightUnit == 'kg' 
                                ? const Color(0xFF3DDC97) 
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(11),
                              bottomLeft: Radius.circular(11),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'kg',
                              style: TextStyle(
                                color: _weightUnit == 'kg' 
                                    ? Colors.white 
                                    : const Color(0xFF555555),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _weightUnit = 'lb';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _weightUnit == 'lb' 
                                ? const Color(0xFF3DDC97) 
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(11),
                              bottomRight: Radius.circular(11),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'lb',
                              style: TextStyle(
                                color: _weightUnit == 'lb' 
                                    ? Colors.white 
                                    : const Color(0xFF555555),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ],
    );
  }

  Widget _buildHeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '키',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '키를 입력해주세요';
                  }
                  if (double.tryParse(value) == null) {
                    return '올바른 키를 입력해주세요';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: '키를 입력해주세요',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.2,
                  ),
                  prefixIcon: const Icon(
                    Icons.height,
                    color: Color(0xFF3DDC97),
                    size: 22,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FFFE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3DDC97),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FFFE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _heightUnit = 'cm';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _heightUnit == 'cm' 
                                ? const Color(0xFF3DDC97) 
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(11),
                              bottomLeft: Radius.circular(11),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'cm',
                              style: TextStyle(
                                color: _heightUnit == 'cm' 
                                    ? Colors.white 
                                    : const Color(0xFF555555),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _heightUnit = 'inch';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _heightUnit == 'inch' 
                                ? const Color(0xFF3DDC97) 
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(11),
                              bottomRight: Radius.circular(11),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'inch',
                              style: TextStyle(
                                color: _heightUnit == 'inch' 
                                    ? Colors.white 
                                    : const Color(0xFF555555),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    double? fontSize,
    double? height,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize ?? 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF555555),
            height: height ?? 1.2,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: fontSize ?? 14,
              height: height ?? 1.2,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF3DDC97),
              size: 22,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FFFE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3DDC97),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
          ),
        ),
      ],
    );
  }

  // 1단계: 기본 정보
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '프로필 설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 15),
        
        // 닉네임 설정
        _buildTextField(
          controller: _nameController,
          label: '닉네임 설정',
          hint: '이름을 입력해주세요',
          icon: Icons.person_outline,
          fontSize: 14,
          height: 1.2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '닉네임을 입력해주세요';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 15),
        
        // 나이와 성별
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                controller: _ageController,
                label: '나이',
                hint: '나이를 입력해주세요',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                fontSize: 14,
                height: 1.2,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '나이를 입력해주세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '올바른 나이를 입력해주세요';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildGenderField(),
            ),
          ],
        ),
        
        const SizedBox(height: 15),
        
        // 키
        _buildHeightField(),
        
        const SizedBox(height: 15),
        
        // 몸무게
        _buildWeightField(),
      ],
    );
  }

  // 2단계: 다이어트 설정
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '다이어트 설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 15),
        
        // 목표 체중
        _buildTargetWeightField(),
        
        const SizedBox(height: 15),
        
        // 다이어트 방법 선택
        _buildDietMethodField(),
        
        const SizedBox(height: 15),
        
        // 다이어트 시작일
        _buildDietStartDateField(),
      ],
    );
  }

  // 목표 체중 필드
  Widget _buildTargetWeightField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '목표 체중',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _targetWeightController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '목표 체중을 입력해주세요';
                  }
                  if (double.tryParse(value) == null) {
                    return '올바른 체중을 입력해주세요';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: '목표 체중을 입력하세요',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.2,
                  ),
                  prefixIcon: const Icon(
                    Icons.track_changes,
                    color: Color(0xFF3DDC97),
                    size: 22,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FFFE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3DDC97),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FFFE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _targetWeightUnit = 'kg';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _targetWeightUnit == 'kg' 
                                ? const Color(0xFF3DDC97) 
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(11),
                              bottomLeft: Radius.circular(11),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'kg',
                              style: TextStyle(
                                color: _targetWeightUnit == 'kg' 
                                    ? Colors.white 
                                    : const Color(0xFF555555),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _targetWeightUnit = 'lb';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _targetWeightUnit == 'lb' 
                                ? const Color(0xFF3DDC97) 
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(11),
                              bottomRight: Radius.circular(11),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'lb',
                              style: TextStyle(
                                color: _targetWeightUnit == 'lb' 
                                    ? Colors.white 
                                    : const Color(0xFF555555),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      ],
    );
  }

  // 다이어트 방법 선택 필드
  Widget _buildDietMethodField() {
    if (_isLoadingDietMethods) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            color: Color(0xFF3DDC97),
          ),
        ),
      );
    }

    if (_dietMethods.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            '다이어트 방법을 불러올 수 없습니다.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF555555),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '다이어트 방법',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        ..._dietMethods.map((method) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDietMethod = method.id;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _selectedDietMethod == method.id
                      ? const Color(0xFFE7FBEC)
                      : const Color(0xFFF8FFFE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDietMethod == method.id
                        ? const Color(0xFF3DDC97)
                        : Colors.grey[300]!,
                    width: _selectedDietMethod == method.id ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedDietMethod == method.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: _selectedDietMethod == method.id
                          ? const Color(0xFF3DDC97)
                          : Colors.grey[400],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedDietMethod == method.id
                                  ? const Color(0xFF3DDC97)
                                  : const Color(0xFF555555),
                            ),
                          ),
                          if (method.shortDescription != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              method.shortDescription!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // 다이어트 시작일 선택 필드
  Widget _buildDietStartDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '다이어트 시작일',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF555555),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dietStartDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF3DDC97),
                      onPrimary: Colors.white,
                      onSurface: Color(0xFF555555),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _dietStartDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FFFE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF3DDC97),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_dietStartDate.year}년 ${_dietStartDate.month}월 ${_dietStartDate.day}일',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
