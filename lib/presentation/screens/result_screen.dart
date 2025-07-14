import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  final String imageUrl;
  final Map<String, dynamic> inferenceData;

  const ResultScreen({
    super.key,
    required this.imageUrl,
    required this.inferenceData,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool showOverlay1 = true;
  bool showOverlay2 = false;
  bool showOverlay3 = false;

  @override
  Widget build(BuildContext context) {
    final String baseImageUrl = widget.imageUrl;
    final String overlayImageUrl = widget.imageUrl; // ✅ 오버레이는 서버에서 같은 경로로 응답했다고 가정

    final prediction = widget.inferenceData['prediction'] ?? '결과 없음';
    final details = widget.inferenceData['details'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 진단 결과'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ 이미지 영역
            Expanded(
              child: Center(
                child: Image.network(
                  (showOverlay1 || showOverlay2 || showOverlay3)
                      ? overlayImageUrl
                      : baseImageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ 스위치 3개 (오버레이 옵션)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSwitch("충치/치주염/치은염", showOverlay1, (val) {
                  setState(() => showOverlay1 = val);
                }),
                _buildSwitch("치석/보철물", showOverlay2, (val) {
                  setState(() => showOverlay2 = val);
                }),
                _buildSwitch("치아번호", showOverlay3, (val) {
                  setState(() => showOverlay3 = val);
                }),
              ],
            ),

            const SizedBox(height: 8),

            // ✅ 진단 결과 텍스트
            Text(
              '🔍 AI 예측 결과: $prediction',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            if (details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  children: List.generate(
                    details.length,
                    (i) => Text('・${details[i]}'),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ✅ 버튼 2개 (저장, 비대면 진료)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text("이미지 저장"),
                    onPressed: () {
                      // TODO: 저장 로직 구현
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('이미지를 저장했습니다.')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.local_hospital),
                    label: const Text("AI 비대면 진료"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      // TODO: 비대면 진료 신청 로직 구현
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('AI 비대면 진료 신청이 완료되었습니다.')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Column(
      children: [
        Switch(value: value, onChanged: onChanged),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
