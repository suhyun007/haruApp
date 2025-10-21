import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/weight_provider.dart';
import '../models/weight_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _weightController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoaded = false;
  bool _isLoadingWeights = false;
  List<Map<String, dynamic>> _weightRecords = [];
  String _chartType = 'line'; // 'line' 또는 'bar'
  double? _currentWeight;
  double? _startWeight;
  double? _targetWeight;
  String? _lastRecordDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLoaded) {
        _loadWeightRecords();
        _isLoaded = true;
      }
    });
  }

  Future<void> _loadWeightRecords() async {
    setState(() {
      _isLoadingWeights = true;
    });

    try {
      final userId = await StorageService.getSupabaseUserId();
      if (userId != null) {
        final records = await ApiService.getWeightRecords(userId);
        final user = await ApiService.getUser(userId);
        
        setState(() {
          _weightRecords = records;
          _isLoadingWeights = false;
          
          // 사용자 정보에서 체중 데이터 가져오기
          if (user != null) {
            _currentWeight = (user['currentWeight'] ?? 0).toDouble();
            _startWeight = (user['currentWeight'] ?? 0).toDouble(); // 첫 번째 기록을 시작체중으로
            _targetWeight = (user['targetWeight'] ?? 0).toDouble();
            
            // 실제 기록이 있으면 첫 번째 기록을 시작체중으로 설정
            if (records.isNotEmpty) {
              _startWeight = (records.first['weight'] ?? 0).toDouble();
              _currentWeight = (records.last['weight'] ?? 0).toDouble();
              _lastRecordDate = records.last['date'];
            }
          }
        });
        debugPrint('체중 기록 ${records.length}개 조회 완료');
      } else {
        setState(() {
          _isLoadingWeights = false;
        });
      }
    } catch (e) {
      debugPrint('체중 기록 조회 실패: $e');
      setState(() {
        _isLoadingWeights = false;
      });
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _showAddWeightDialog() {
    _weightController.clear();
    _memoController.clear();
    _selectedDate = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('체중 기록'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: '체중 (kg)',
                  hintText: '예: 70.5',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF3DDC97),
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Color(0xFF555555),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '날짜',
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  hintText: '간단한 메모를 남겨보세요',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: _submitWeight,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DDC97),
              ),
              child: const Text('저장', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitWeight() async {
    final weight = double.tryParse(_weightController.text);
    if (weight != null && weight > 0) {
      try {
        final userId = await StorageService.getSupabaseUserId();
        if (userId != null) {
          await ApiService.createWeightRecord(
            userId: userId,
            weight: weight,
            weightUnit: 'kg',
            date: _selectedDate,
            memo: _memoController.text.isEmpty ? null : _memoController.text,
          );

          // 저장 후 목록 새로고침
          await _loadWeightRecords();
          
          if (mounted) {
            _weightController.clear();
            _memoController.clear();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('체중이 기록되었습니다'),
                backgroundColor: Color(0xFF3DDC97),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('저장 중 오류가 발생했습니다: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: _isLoadingWeights
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF3DDC97),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // 체중 요약 정보
                  _buildWeightSummary(),
                  const SizedBox(height: 15),
                  // 진행 상황 텍스트 (꺾은선 영역 위)
                  if (_startWeight != null && _targetWeight != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '현재까지 감량량 : ${(_startWeight! - _currentWeight!).toStringAsFixed(1)} kg',
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                        Text(
                          '목표체중까지 : ${(_currentWeight! - _targetWeight!).toStringAsFixed(1)} kg',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // 그래프 타입 선택 버튼
                  if (_weightRecords.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildChartTypeButton('line', Icons.show_chart, ''),
                        const SizedBox(width: 8),
                        _buildChartTypeButton('bar', Icons.bar_chart, ''),
                      ],
                    ),
                    const SizedBox(height: 0),
                    _buildWeightChart(),
                    const SizedBox(height: 0),
                  ],
                  if (_weightRecords.isEmpty)
                    Card(
                      color: Colors.white,
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text(
                            '아직 기록된 체중이 없습니다',
                            style: TextStyle(color: Color(0xFF555555)),
                          ),
                        ),
                      ),
                    )
                  else
                    _buildWeightTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildChartTypeButton(String type, IconData icon, String label) {
    final isSelected = _chartType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _chartType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3DDC97) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3DDC97) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2C3E50), // 진한 회색-파랑
            const Color(0xFF34495E), // 중간 회색-파랑
            const Color(0xFF2C3E50), // 하단 진한 회색-파랑
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1A252F),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '현재 체중',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              FloatingActionButton(
                onPressed: _showAddWeightDialog,
                backgroundColor: Colors.white,
                mini: true,
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF333333),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showEditWeightDialog('현재 체중', _currentWeight),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_currentWeight?.toStringAsFixed(1) ?? '0.0'} kg',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildRecordStatus(),
          const SizedBox(height: 16),
          // 시작체중, 목표체중을 아래에 표시
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      '시작 체중',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _showEditWeightDialog('시작 체중', _startWeight),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        child: Text(
                          '${_startWeight?.toStringAsFixed(1) ?? '0.0'} kg',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      '목표 체중',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                      InkWell(
                        onTap: () => _showEditWeightDialog('목표 체중', _targetWeight),
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.25),
                                Colors.white.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        child: Text(
                          '${_targetWeight?.toStringAsFixed(1) ?? '0.0'} kg',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInfoCard(String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInfo(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditWeightDialog(String type, double? currentValue) {
    final controller = TextEditingController(text: currentValue?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type 수정'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '체중 (kg)',
            hintText: '예: 70.5',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = double.tryParse(controller.text);
              if (newValue != null) {
                setState(() {
                  if (type == '시작 체중') {
                    _startWeight = newValue;
                  } else if (type == '목표 체중') {
                    _targetWeight = newValue;
                  } else if (type == '현재 체중') {
                    _currentWeight = newValue;
                    // 현재 체중이 변경되면 체중 기록도 업데이트
                    if (_weightRecords.isNotEmpty) {
                      _weightRecords.last['weight'] = newValue;
                    }
                  }
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3DDC97),
            ),
            child: const Text('저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordStatus() {
    if (_lastRecordDate == null) {
      return const Text(
        '아직 기록된 체중이 없습니다',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      );
    }

    final lastRecord = DateTime.parse(_lastRecordDate!);
    final today = DateTime.now();
    final difference = today.difference(lastRecord).inDays;

    String statusText;
    if (difference == 0) {
      statusText = '오늘 몸무게 기록 완료!';
    } else if (difference == 1) {
      statusText = '어제 몸무게 기록됨';
    } else {
      statusText = '몸무게 기록한지 $difference일 전';
    }

    return Text(
      statusText,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
    );
  }

  Widget _buildWeightTable() {
    // 년도별로 데이터 그룹화
    final Map<int, List<Map<String, dynamic>>> recordsByYear = {};
    for (final record in _weightRecords) {
      final year = DateTime.parse(record['date']).year;
      if (!recordsByYear.containsKey(year)) {
        recordsByYear[year] = [];
      }
      recordsByYear[year]!.add(record);
    }

    // 년도별로 정렬 (최신 년도부터)
    final sortedYears = recordsByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedYears.map((year) {
        final yearRecords = recordsByYear[year]!;
        return Column(
          children: [
            // 년도 헤더 (테이블 밖으로)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                '$year년',
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // 테이블
            Card(
              color: Colors.white,
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // 테이블 헤더
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            '날짜',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '체중',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '메모',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 테이블 데이터
                  ...yearRecords.reversed.map((record) {
                    final weight = (record['weight'] ?? 0).toDouble();
                    final date = DateTime.parse(record['date']);
                    final memo = record['memo'] ?? '';
                    
                    return InkWell(
                      onTap: () => _showEditWeightRecordDialog(record),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                DateFormat('MM/dd').format(date),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF555555),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${weight.toStringAsFixed(1)} kg',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                memo,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: memo.isEmpty ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showEditWeightRecordDialog(Map<String, dynamic> record) {
    final weightController = TextEditingController(text: record['weight'].toString());
    final memoController = TextEditingController(text: record['memo'] ?? '');
    DateTime selectedDate = DateTime.parse(record['date']);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('체중 기록 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: '체중 (kg)',
                  hintText: '예: 70.5',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFF3DDC97),
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: Color(0xFF555555),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '날짜',
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memoController,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  hintText: '간단한 메모를 남겨보세요',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newWeight = double.tryParse(weightController.text);
                if (newWeight != null) {
                  // API로 체중 기록 수정
                  try {
                    await ApiService.updateWeightRecord(record['id'], {
                      'weight': newWeight,
                      'date': selectedDate.toIso8601String(),
                      'memo': memoController.text,
                    });
                    debugPrint('API 수정 성공');
                    
                    // API 성공 후 로컬 상태 업데이트
                    setState(() {
                      final index = _weightRecords.indexWhere((r) => r['id'] == record['id']);
                      debugPrint('수정할 인덱스: $index');
                      debugPrint('수정 전 데이터: ${_weightRecords[index]}');
                      
                      if (index != -1) {
                        _weightRecords[index] = {
                          ..._weightRecords[index],
                          'weight': newWeight,
                          'date': selectedDate.toIso8601String(),
                          'memo': memoController.text,
                        };
                        
                        debugPrint('수정 후 데이터: ${_weightRecords[index]}');
                        
                        // 현재 체중도 업데이트 (최신 기록이면)
                        if (index == _weightRecords.length - 1) {
                          _currentWeight = newWeight;
                        }
                      }
                    });
                  } catch (e) {
                    debugPrint('API 수정 실패: $e');
                    // API 실패 시에도 로컬 상태는 업데이트
                    setState(() {
                      final index = _weightRecords.indexWhere((r) => r['id'] == record['id']);
                      if (index != -1) {
                        _weightRecords[index] = {
                          ..._weightRecords[index],
                          'weight': newWeight,
                          'date': selectedDate.toIso8601String(),
                          'memo': memoController.text,
                        };
                        
                        if (index == _weightRecords.length - 1) {
                          _currentWeight = newWeight;
                        }
                      }
                    });
                  }
                  
                  Navigator.pop(context);
                  
                  // 데이터 다시 로드하여 테이블 새로고침
                  await _loadWeightRecords();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('체중 기록이 수정되었습니다'),
                      backgroundColor: Color(0xFF3DDC97),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3DDC97),
              ),
              child: const Text('저장', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    if (_weightRecords.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 250,
          child: _chartType == 'line' ? _buildLineChart() : _buildBarChart(),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final spots = _weightRecords
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              (entry.value['weight'] ?? 0).toDouble(),
            ))
        .toList();

    // 최소/최대 체중 계산
    final weights = _weightRecords.map((r) => (r['weight'] ?? 0).toDouble()).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    
    return LineChart(
      LineChartData(
        minY: minWeight - (weightRange * 0.1), // 10% 여유 공간
        maxY: maxWeight + (weightRange * 0.1), // 10% 여유 공간
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF555555),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _weightRecords.length) {
                  final date = DateTime.parse(_weightRecords[value.toInt()]['date']);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF555555),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF3DDC97),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF3DDC97),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF3DDC97).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    // 최소/최대 체중 계산
    final weights = _weightRecords.map((r) => (r['weight'] ?? 0).toDouble()).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    
    final barGroups = _weightRecords
        .asMap()
        .entries
        .map((entry) => BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: (entry.value['weight'] ?? 0).toDouble(),
                  color: const Color(0xFF3DDC97),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ))
        .toList();

    return BarChart(
      BarChartData(
        minY: minWeight - (weightRange * 0.1), // 10% 여유 공간
        maxY: maxWeight + (weightRange * 0.1), // 10% 여유 공간
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF555555),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _weightRecords.length) {
                  final date = DateTime.parse(_weightRecords[value.toInt()]['date']);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF555555),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        barGroups: barGroups,
      ),
    );
  }
}

