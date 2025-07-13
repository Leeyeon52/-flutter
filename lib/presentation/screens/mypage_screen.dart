import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/presentation/viewmodel/auth_viewmodel.dart';
import '/presentation/viewmodel/userinfo_viewmodel.dart'; // UserInfoViewModel 임포트

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'P'; // Default role for deletion

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final userInfoViewModel = Provider.of<UserInfoViewModel>(context); // UserInfoViewModel 가져오기

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '환영합니다, ${userInfoViewModel.user?.id ?? '손님'}님!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                authViewModel.logout();
                userInfoViewModel.clearUser(); // 로그아웃 시 UserInfoViewModel 초기화
                context.go('/login');
              },
              child: const Text('로그아웃'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // ✅ _showDeleteAccountDialog 호출 시 userInfoViewModel 전달
                _showDeleteAccountDialog(context, authViewModel, userInfoViewModel);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('회원 탈퇴', style: TextStyle(color: Colors.white)),
            ),
            if (authViewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  authViewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ userInfoViewModel 매개변수 추가
  void _showDeleteAccountDialog(BuildContext context, AuthViewModel authViewModel, UserInfoViewModel userInfoViewModel) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('회원 탈퇴를 위해 아이디와 비밀번호를 입력해주세요.'),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(labelText: '아이디'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
              ),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: '역할'),
                items: const [
                  DropdownMenuItem(value: 'P', child: Text('환자')),
                  DropdownMenuItem(value: 'D', child: Text('의사')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: authViewModel.isLoading
                  ? null
                  : () async {
                      final String registerId = _idController.text;
                      final String password = _passwordController.text;
                      final String role = _selectedRole;

                      final error = await authViewModel.deleteUser(registerId, password, role);

                      if (error == null) {
                        if (mounted) {
                          Navigator.of(dialogContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
                          );
                          authViewModel.logout(); // 탈퇴 성공 시 로그아웃 처리
                          userInfoViewModel.clearUser(); // ✅ UserInfoViewModel 초기화
                          context.go('/login'); // 로그인 화면으로 이동
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      }
                    },
              child: authViewModel.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('탈퇴'),
            ),
          ],
        );
      },
    );
  }
}
