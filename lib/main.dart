import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv 임포트

// 기존 임포트
import 'presentation/viewmodel/userinfo_viewmodel.dart';
import 'services/router.dart';
import '/presentation/screens/doctor/d_home_screen.dart';
import '/presentation/viewmodel/doctor/d_consultation_record_viewmodel.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_patient_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';
import '/presentation/viewmodel/chatbot_viewmodel.dart';
import '/presentation/viewmodel/patient_inference_viewmodel.dart';

// ✅ 새로 추가할 임포트
import 'package:ultralytics_yolo_example/presentation/viewmodel/history_viewmodel.dart'; // HistoryViewModel 임포트
import 'package:ultralytics_yolo_example/presentation/viewmodel/clinics_viewmodel.dart'; // ClinicsViewModel 임포트

Future<void> main() async {
  // ✅ .env 파일 로드 (가장 먼저 실행되어야 함)
  await dotenv.load(fileName: ".env");

  const String globalBaseUrl = "http://192.168.0.2:5000/api";

  // ✅ GEMINI_API_KEY 가져오기
  final String? geminiApiKey = dotenv.env['GEMINI_API_KEY'];
  if (geminiApiKey == null || geminiApiKey.isEmpty) {
    throw Exception('❌ GEMINI_API_KEY not found in .env file or is empty');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(baseUrl: globalBaseUrl),
        ),
        // ✅ UserInfoViewModel 생성 시 AuthViewModel 주입
        ChangeNotifierProvider(
          create: (context) => UserInfoViewModel(
            authViewModel: Provider.of<AuthViewModel>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DoctorDashboardViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => DPatientViewModel(baseUrl: globalBaseUrl),
        ),
        ChangeNotifierProvider(
          create: (_) => ConsultationRecordViewModel(baseUrl: globalBaseUrl),
        ),
        ChangeNotifierProvider(
          // ✅ ChatbotViewModel에 apiKey 주입
          create: (_) => ChatbotViewModel(apiKey: geminiApiKey, baseUrl: globalBaseUrl),
        ),
        ChangeNotifierProvider(
          create: (_) => PatientInferenceViewModel(baseUrl: globalBaseUrl),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => ClinicsViewModel(),
        ),
      ],
      child: YOLOExampleApp(baseUrl: globalBaseUrl),
    ),
  );
}

class YOLOExampleApp extends StatelessWidget {
  final String baseUrl;

  const YOLOExampleApp({super.key, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'YOLO Plugin Example',
      debugShowCheckedModeBanner: false,
      routerConfig: createRouter(baseUrl),
      theme: ThemeData(
        primaryColor: const Color(0xFF42A5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF42A5F5),
        ),
      ),
    );
  }
}
