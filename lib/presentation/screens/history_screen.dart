import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ✅ 패키지 경로로 임포트 변경 (프로젝트 이름에 맞게 'ultralytics_yolo_example' 수정)
import 'package:ultralytics_yolo_example/presentation/viewmodel/history_viewmodel.dart';
import 'package:ultralytics_yolo_example/presentation/screens/history_detail_screen.dart'; // ✅ 패키지 경로로 임포트 변경

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<HistoryViewModel>(context);
    final keywordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('이전 진단 내역'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: keywordController,
                  decoration: InputDecoration(
                    labelText: '키워드 검색 (예: 충치, 잇몸)',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        viewModel.search(keywordController.text);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            viewModel.filterByDate(picked.start, picked.end);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(viewModel.startDate == null
                            ? '날짜 필터링'
                            : '${viewModel.startDate!.toLocal().toIso8601String().substring(0, 10)} ~ ${viewModel.endDate!.toLocal().toIso8601String().substring(0, 10)}'),
                      ),
                    ),
                    if (viewModel.startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => viewModel.clearFilter(),
                      ),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: viewModel.records.length,
              itemBuilder: (context, index) {
                final record = viewModel.records[index];
                return Card(
                  color: Colors.grey[100],
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        record.thumbnailUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    title: Text('진단 날짜: ${record.date.toLocal().toIso8601String().substring(0, 10)}'),
                    subtitle: Text(record.summary),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // ✅ 상세화면으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HistoryDetailScreen(
                            date: record.date.toLocal().toIso8601String().substring(0, 10),
                            summary: record.summary,
                            details: record.details,
                            imageUrl: record.imageUrl,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
