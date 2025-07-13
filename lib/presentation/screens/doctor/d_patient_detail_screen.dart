import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/doctor/d_patient_viewmodel.dart';
import '/presentation/model/doctor/d_patient.dart';
import '/presentation/model/doctor/d_consultation_record.dart';

class PatientDetailScreen extends StatefulWidget {
  final int patientId;

  const PatientDetailScreen({required this.patientId, super.key});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  Patient? _patient;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPatient();
    });
  }

  Future<void> _fetchPatient() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final patientViewModel = context.read<DPatientViewModel>();

    try {
      await patientViewModel.fetchPatient(widget.patientId);
      if (patientViewModel.errorMessage != null) {
        throw Exception(patientViewModel.errorMessage);
      }
      _patient = patientViewModel.currentPatient;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('환자 상세 정보')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('환자 상세 정보')),
        body: Center(child: Text('오류: $_errorMessage')),
      );
    }

    if (_patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('환자 상세 정보')),
        body: const Center(child: Text('환자 정보를 찾을 수 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_patient!.name} 환자 상세 정보', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 환자 기본 정보
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('환자 기본 정보', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 10),
                    _buildInfoRow('이름', _patient!.name),
                    _buildInfoRow('생년월일', _patient!.dateOfBirth),
                    _buildInfoRow('성별', _patient!.gender),
                    _buildInfoRow('연락처', _patient!.phoneNumber ?? 'N/A'),
                    _buildInfoRow('주소', _patient!.address ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('진단 결과 예시 (MongoDB)', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            // 여기는 향후 진단 결과 화면으로 이동하도록 안내
            const Center(
              child: Text('이 환자의 진단 기록은 진단 결과 탭에서 확인할 수 있습니다.'),
            ),
          ],
        ),
      ),
    );
  }
}