import 'package:flutter/material.dart';
import '../../services/kakao_auth_service.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'package:snob/screens/onboarding_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  User? user;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadUser();
  }

  // ============================================================
  // 카카오 사용자 정보 가져오기
  // ============================================================

  Future<void> _loadUser() async {
    try {
      final isLoggedIn =
          await KakaoAuthService.checkToken();

      if (!isLoggedIn) {
        if (!mounted) return;

        setState(() {
          user = null;
          isLoading = false;
        });

        return;
      }

      final kakaoUser =
          await UserApi.instance.me();

      if (!mounted) return;

      setState(() {
        user = kakaoUser;
        isLoading = false;
      });
    } catch (e) {
      print('카카오 사용자 정보 조회 실패: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // ============================================================
  // 로그아웃
  // ============================================================

  Future<void> _logout() async {
    try {
      await KakaoAuthService.logout();

      if (!mounted) return;

      // 로그인 화면으로 이동하면서
      // 기존 화면 스택을 모두 제거
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      print('로그아웃 실패: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그아웃 중 문제가 발생했습니다.'),
        ),
      );
    }
  }

  // ============================================================
  // 화면
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [

                // ==================================================
                // 프로필
                // ==================================================

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [

                      CircleAvatar(
                        radius: 32,
                        backgroundColor:
                            Colors.grey.shade300,
                        backgroundImage:
                            user?.kakaoAccount?.profile
                                        ?.profileImageUrl !=
                                    null
                                ? NetworkImage(
                                    user!
                                        .kakaoAccount!
                                        .profile!
                                        .profileImageUrl!,
                                  )
                                : null,
                        child: user
                                    ?.kakaoAccount
                                    ?.profile
                                    ?.profileImageUrl ==
                                null
                            ? const Icon(
                                Icons.person,
                                size: 35,
                                color: Colors.white,
                              )
                            : null,
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              user
                                      ?.kakaoAccount
                                      ?.profile
                                      ?.nickname ??
                                  '여행자',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              'SNOB와 함께 여행을 시작해보세요.',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // 나의 여행
                // ==================================================

                const Text(
                  '나의 여행',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [

                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.map_outlined,
                        ),
                      ),

                      const SizedBox(width: 14),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              '현재 여행',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              '아직 만들어진 여행 일정이 없어요.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // 나의 여행 성향
                // ==================================================

                const Text(
                  '나의 여행 성향',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [

                          _buildPreference(
                            icon: Icons.park_outlined,
                            title: '자연',
                          ),

                          _buildPreference(
                            icon:
                                Icons.location_city_outlined,
                            title: '도시',
                          ),

                          _buildPreference(
                            icon: Icons.people_outline,
                            title: '사람',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // 나중에 성향 테스트 다시 연결
                          },
                          child: const Text(
                            '성향 다시 검사',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // 여행 기록
                // ==================================================

                const Text(
                  '여행 기록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [

                      Icon(
                        Icons.menu_book_outlined,
                        size: 30,
                        color: Colors.grey,
                      ),

                      SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              '여행 기록',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              '완료한 여행이 여기에 기록돼요.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // 설정
                // ==================================================

                const Text(
                  '설정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.notifications_none,
                  ),
                  title: const Text(
                    '알림 설정',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    // 나중에 연결
                  },
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.logout,
                  ),
                  title: const Text(
                    '로그아웃',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                  onTap: _logout,
                ),

                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // ================================================================
  // 여행 성향 아이콘
  // ================================================================

  static Widget _buildPreference({
    required IconData icon,
    required String title,
  }) {
    return Column(
      children: [

        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 26,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}