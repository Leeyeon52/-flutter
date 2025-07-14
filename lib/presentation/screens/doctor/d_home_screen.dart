import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/screens/doctor/d_patient_list_screen.dart';
import '/presentation/screens/doctor/d_inference_result_screen.dart';
import '/presentation/viewmodel/doctor/d_dashboard_viewmodel.dart';

// Note: DoctorMenu enum은 d_dashboard_viewmodel.dart에서 임포트됩니다.

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              '진료 캘린더 기능은 현재 개발 중입니다.',
              style: TextStyle(fontSize: 20, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            Text(
              '곧 업데이트될 예정입니다!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorHomeScreen extends StatelessWidget {
  final String baseUrl;

  const DoctorHomeScreen({super.key, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    final dashboardViewModel = context.watch<DoctorDashboardViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (kDebugMode) {
      print('--- DoctorHomeScreen rebuild cycle START ---');
      print('Current User (at build start): $currentUser');
      print('Is Current User Doctor (at build start): ${currentUser?.isDoctor}');
    }

    if (currentUser == null) {
      if (kDebugMode) {
        print('DoctorHomeScreen: currentUser is NULL. Showing access denied message.');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login'); // 로그인 화면으로 강제 이동
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!currentUser.isDoctor) {
      if (kDebugMode) {
        print('DoctorHomeScreen: currentUser is NOT a doctor. Showing access denied message.');
      }
      return const Scaffold(
        body: Center(child: Text('의사 계정으로 로그인해야 환자 목록을 볼 수 있습니다.')),
      );
    }

    if (kDebugMode) {
      print('DoctorHomeScreen: currentUser is valid and is a doctor. Proceeding to main content.');
      print('--- DoctorHomeScreen rebuild cycle END ---');
    }

    Widget mainContent;
    switch (dashboardViewModel.selectedMenu) {
      case DoctorMenu.inferenceResult:
        mainContent = InferenceResultScreen(baseUrl: baseUrl);
        break;
      case DoctorMenu.calendar:
        mainContent = const CalendarScreen();
        break;
      case DoctorMenu.patientList:
        mainContent = const PatientListScreen();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TOOTH AI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent, // AppBar 배경색
        elevation: 4, // AppBar 그림자
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white), // 아이콘 색상
            onPressed: () {
              authViewModel.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: mainContent,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: dashboardViewModel.selectedIndex,
        onTap: (index) {
          if (kDebugMode) {
            print('BottomNavigationBar tapped: index = $index');
            print('AuthViewModel currentUser before tab switch: ${authViewModel.currentUser?.isDoctor}');
          }
          dashboardViewModel.setSelectedIndex(index);
        },
        selectedItemColor: Colors.blueAccent, // 선택된 아이템 색상
        unselectedItemColor: Colors.grey[600], // 선택되지 않은 아이템 색상
        backgroundColor: Colors.white, // 배경색
        elevation: 8, // 그림자
        type: BottomNavigationBarType.fixed, // 아이템이 많아도 고정되도록
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '진단 결과',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '에약 현황',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt),
            label: '환자 목록',
          ),
        ],
      ),
    );
  }
}
