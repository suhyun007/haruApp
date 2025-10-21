import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../models/diet_method_model.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _calorieGoalController = TextEditingController();
  List<DietMethodModel> _dietMethods = [];
  String? _selectedDietMethodId;
  bool _isLoadingDietMethods = false;

  @override
  void dispose() {
    _nameController.dispose();
    _targetWeightController.dispose();
    _calorieGoalController.dispose();
    super.dispose();
  }

  void _showEditDialog(UserModel user) async {
    _nameController.text = user.name;
    _targetWeightController.text = user.targetWeight.toString();
    _calorieGoalController.text = user.dailyCalorieGoal.toString();
    _selectedDietMethodId = null;

    // 다이어트 방법 목록 로드
    setState(() {
      _isLoadingDietMethods = true;
    });

    try {
      final methods = await ApiService.getDietMethods();
      setState(() {
        _dietMethods = methods;
        _isLoadingDietMethods = false;
        // 현재 사용자의 다이어트 방법 찾기
        if (user.dietMethodName != null) {
          final currentMethod = methods.firstWhere(
            (m) => m.name == user.dietMethodName,
            orElse: () => methods.first,
          );
          _selectedDietMethodId = currentMethod.id;
        } else if (methods.isNotEmpty) {
          _selectedDietMethodId = methods.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingDietMethods = false;
      });
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로필 수정'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '이름'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력하세요';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _targetWeightController,
                  decoration: const InputDecoration(labelText: '목표 체중 (kg)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '목표 체중을 입력하세요';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _calorieGoalController,
                  decoration: const InputDecoration(labelText: '하루 칼로리 목표 (kcal)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '칼로리 목표를 입력하세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_isLoadingDietMethods)
                  const CircularProgressIndicator(
                    color: Color(0xFF3DDC97),
                  )
                else if (_dietMethods.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '다이어트 방법',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF555555),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._dietMethods.map((method) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDietMethodId = method.id;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _selectedDietMethodId == method.id
                                    ? const Color(0xFFE7FBEC)
                                    : const Color(0xFFF8FFFE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedDietMethodId == method.id
                                      ? const Color(0xFF3DDC97)
                                      : Colors.grey[300]!,
                                  width: _selectedDietMethodId == method.id ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _selectedDietMethodId == method.id
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: _selectedDietMethodId == method.id
                                        ? const Color(0xFF3DDC97)
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      method.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedDietMethodId == method.id
                                            ? const Color(0xFF3DDC97)
                                            : const Color(0xFF555555),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => _submitProfile(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3DDC97),
            ),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProfile(UserModel user) async {
    if (_formKey.currentState!.validate()) {
      // 선택된 다이어트 방법 찾기
      final selectedMethod = _dietMethods.firstWhere(
        (m) => m.id == _selectedDietMethodId,
        orElse: () => _dietMethods.first,
      );

      // API 서버에 업데이트
      final apiResponse = await ApiService.updateUser({
        'id': user.id,
        'nickname': _nameController.text,
        'age': user.age,
        'gender': user.gender == '여성' ? 'female' : 'male',
        'height': user.height,
        'heightUnit': 'cm',
        'currentWeight': user.currentWeight,
        'currentWeightUnit': 'kg',
        'targetWeight': double.parse(_targetWeightController.text),
        'targetWeightUnit': 'kg',
        'dietMethodId': _selectedDietMethodId,
        'dailyCalorieGoal': int.parse(_calorieGoalController.text),
      });

      if (apiResponse != null) {
        final updatedUser = UserModel(
          id: user.id,
          name: _nameController.text,
          age: user.age,
          height: user.height,
          targetWeight: double.parse(_targetWeightController.text),
          currentWeight: user.currentWeight,
          dailyCalorieGoal: int.parse(_calorieGoalController.text),
          gender: user.gender,
          dietMethodName: selectedMethod.name,
          dietMethodDescription: selectedMethod.description,
        );

        Provider.of<UserProvider>(context, listen: false).updateUser(updatedUser);
        
        // 로컬 스토리지에 저장
        await StorageService.saveUser(updatedUser);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필이 수정되었습니다'),
              backgroundColor: Color(0xFF3DDC97),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFFE7FBEC),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.monitor_weight, color: Color(0xFF3DDC97)),
                      title: const Text('현재 체중'),
                      trailing: Text(
                        '${user.currentWeight.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.flag, color: Color(0xFF3DDC97)),
                      title: const Text('목표 체중'),
                      trailing: Text(
                        '${user.targetWeight.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.local_fire_department, color: Colors.orange),
                      title: const Text('하루 칼로리 목표'),
                      trailing: Text(
                        '${user.dailyCalorieGoal} kcal',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showEditDialog(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3DDC97),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '프로필 수정',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showResetDialog(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '데이터 초기화',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 초기화'),
        content: const Text('모든 데이터가 삭제되고 온보딩 화면으로 이동합니다.\n계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              // 로컬 데이터 삭제
              await StorageService.clearUser();
              
              if (mounted) {
                Navigator.pop(context);
                // 온보딩 화면으로 이동
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/onboarding',
                  (route) => false,
                );
              }
            },
            child: const Text('확인', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

