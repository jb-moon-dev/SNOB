import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen
    extends StatefulWidget {
  const NotificationSettingsScreen({
    super.key,
  });

  @override
  State<NotificationSettingsScreen>
      createState() =>
          _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<
        NotificationSettingsScreen> {
  bool travelRecommendation = true;
  bool travelReminder = true;
  bool snobMessage = true;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs =
        await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      travelRecommendation =
          prefs.getBool(
                'notification_recommendation',
              ) ??
              true;

      travelReminder =
          prefs.getBool(
                'notification_reminder',
              ) ??
              true;

      snobMessage =
          prefs.getBool(
                'notification_snob',
              ) ??
              true;

      isLoading = false;
    });
  }

  Future<void> _setValue(
    String key,
    bool value,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      key,
      value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '알림 설정',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                40,
              ),
              children: [
                _buildHeader(),

                const SizedBox(
                  height: 24,
                ),

                _buildSwitch(
                  title: '여행지 추천',
                  subtitle:
                      '나에게 맞는 여행지를 알려드려요.',
                  value:
                      travelRecommendation,
                  onChanged: (value) {
                    setState(() {
                      travelRecommendation =
                          value;
                    });

                    _setValue(
                      'notification_recommendation',
                      value,
                    );
                  },
                ),

                _buildDivider(),

                _buildSwitch(
                  title: '여행 일정 알림',
                  subtitle:
                      '여행 일정과 관련된 알림을 받아요.',
                  value:
                      travelReminder,
                  onChanged: (value) {
                    setState(() {
                      travelReminder =
                          value;
                    });

                    _setValue(
                      'notification_reminder',
                      value,
                    );
                  },
                ),

                _buildDivider(),

                _buildSwitch(
                  title: '오늘의 SNOB',
                  subtitle:
                      '매일 새로운 여행 문구를 받아요.',
                  value: snobMessage,
                  onChanged: (value) {
                    setState(() {
                      snobMessage =
                          value;
                    });

                    _setValue(
                      'notification_snob',
                      value,
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
            child: const Icon(
              Icons.notifications_none,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'SNOB 알림',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(
                    height: 4),
                Text(
                  '원하는 알림만 선택해서 받아보세요.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors
                        .grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>
        onChanged,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
                const SizedBox(
                    height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors
                        .grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade100,
    );
  }
}