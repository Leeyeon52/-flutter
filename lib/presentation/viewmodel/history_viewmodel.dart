import 'package:flutter/material.dart';

// 진단 기록 데이터를 위한 간단한 모델 클래스
class DiagnosisRecord {
  final DateTime date;
  final String summary;
  final String details;
  final String thumbnailUrl;
  final String imageUrl; // 상세 이미지 URL

  DiagnosisRecord({
    required this.date,
    required this.summary,
    required this.details,
    required this.thumbnailUrl,
    required this.imageUrl,
  });
}

class HistoryViewModel extends ChangeNotifier {
  List<DiagnosisRecord> _allRecords = []; // 모든 진단 기록
  List<DiagnosisRecord> _records = []; // 현재 화면에 표시될 기록

  DateTime? _startDate;
  DateTime? _endDate;
  String _keyword = '';

  HistoryViewModel() {
    // 초기 데이터 로드 (실제 앱에서는 여기서 서버 또는 로컬 DB에서 데이터를 가져옵니다)
    _loadDummyData();
  }

  List<DiagnosisRecord> get records => _records;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  void _loadDummyData() {
    _allRecords = [
      DiagnosisRecord(
        date: DateTime(2023, 1, 10),
        summary: '왼쪽 어금니 충치 초기',
        details: '왼쪽 아래 어금니에 작은 충치가 발견되었습니다. 정기적인 검진과 스케일링이 필요합니다.',
        thumbnailUrl: 'https://via.placeholder.com/150/FF5733/FFFFFF?text=Tooth1',
        imageUrl: 'https://via.placeholder.com/600/FF5733/FFFFFF?text=DetailedTooth1',
      ),
      DiagnosisRecord(
        date: DateTime(2023, 3, 15),
        summary: '오른쪽 잇몸 염증',
        details: '오른쪽 잇몸에 경미한 염증이 있습니다. 양치질 습관을 개선하고 치실 사용을 권장합니다.',
        thumbnailUrl: 'https://via.placeholder.com/150/33FF57/FFFFFF?text=Gum2',
        imageUrl: 'https://via.placeholder.com/600/33FF57/FFFFFF?text=DetailedGum2',
      ),
      DiagnosisRecord(
        date: DateTime(2023, 5, 20),
        summary: '사랑니 발치 필요',
        details: '오른쪽 위 사랑니가 매복되어 있어 발치가 필요합니다. X-ray 결과 추가 상담 예정.',
        thumbnailUrl: 'https://via.placeholder.com/150/3357FF/FFFFFF?text=Wisdom3',
        imageUrl: 'https://via.placeholder.com/600/3357FF/FFFFFF?text=DetailedWisdom3',
      ),
      DiagnosisRecord(
        date: DateTime(2024, 7, 5),
        summary: '치아 스케일링 완료',
        details: '정기적인 치아 스케일링을 완료했습니다. 구강 위생 상태가 양호합니다.',
        thumbnailUrl: 'https://via.placeholder.com/150/FFFF33/FFFFFF?text=Scaling4',
        imageUrl: 'https://via.placeholder.com/600/FFFF33/FFFFFF?text=DetailedScaling4',
      ),
      DiagnosisRecord(
        date: DateTime(2024, 6, 12),
        summary: '윗니 일부 변색',
        details: '윗니 두 개에 약간의 변색이 관찰됩니다. 미백 치료 상담 가능합니다.',
        thumbnailUrl: 'https://via.placeholder.com/150/FF33FF/FFFFFF?text=Discolor5',
        imageUrl: 'https://via.placeholder.com/600/FF33FF/FFFFFF?text=DetailedDiscolor5',
      ),
      DiagnosisRecord(
        date: DateTime(2025, 1, 1),
        summary: '정기 검진',
        details: '정기 검진 결과 특이사항 없음',
        thumbnailUrl: 'https://via.placeholder.com/150/AAEEFF/FFFFFF?text=Checkup',
        imageUrl: 'https://via.placeholder.com/600/AAEEFF/FFFFFF?text=CheckupDetail',
      ),
      DiagnosisRecord(
        date: DateTime(2025, 2, 14),
        summary: '충치 치료 완료',
        details: '초기 충치 치료가 성공적으로 완료되었습니다.',
        thumbnailUrl: 'https://via.placeholder.com/150/FFAACC/FFFFFF?text=Cavity',
        imageUrl: 'https://via.placeholder.com/600/FFAACC/FFFFFF?text=CavityDetail',
      ),
    ];
    _applyFilters();
  }

  void search(String keyword) {
    _keyword = keyword.toLowerCase();
    _applyFilters();
  }

  void filterByDate(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
  }

  void clearFilter() {
    _startDate = null;
    _endDate = null;
    _keyword = '';
    _applyFilters();
  }

  void _applyFilters() {
    _records = _allRecords.where((record) {
      bool matchesKeyword = _keyword.isEmpty ||
          record.summary.toLowerCase().contains(_keyword) ||
          record.details.toLowerCase().contains(_keyword);

      bool matchesDate = true;
      if (_startDate != null && _endDate != null) {
        matchesDate = record.date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
                      record.date.isBefore(_endDate!.add(const Duration(days: 1)));
      }
      return matchesKeyword && matchesDate;
    }).toList();

    // 최신 날짜순으로 정렬
    _records.sort((a, b) => b.date.compareTo(a.date));

    notifyListeners(); // 데이터 변경을 UI에 알림
  }
}