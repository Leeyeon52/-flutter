import 'package:flutter/material.dart';

class ResultDetailScreen extends StatelessWidget {
  final String originalImageUrl;
  final String processedImageUrl;

  const ResultDetailScreen({
    super.key,
    required this.originalImageUrl,
    required this.processedImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('결과 이미지 상세 보기')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('📸 원본 이미지', style: TextStyle(fontSize: 18)),
            ),
            Image.network(originalImageUrl, fit: BoxFit.contain),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('🧠 분석 결과 이미지', style: TextStyle(fontSize: 18)),
            ),
            Image.network(processedImageUrl, fit: BoxFit.contain),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}