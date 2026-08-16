import 'package:flutter/material.dart';

import '../course/center50.dart';

class ResultScreen extends StatelessWidget {
  // 심리테스트 결과 유형
  final String personalityType;

  // 추천 지역
  final String recommendedRegion;

  const ResultScreen({
    super.key,
    required this.personalityType,
    required this.recommendedRegion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('여행 성향 결과'),
        centerTitle: true,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // -----------------------------
              // 제목
              // -----------------------------
              const Text(
                '✨ 당신의 여행 성향',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              // -----------------------------
              // 여행 유형
              // -----------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey.shade100,
                ),
                child: Column(
                  children: [
                    const Text(
                      '당신의 여행 유형',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      personalityType,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // -----------------------------
              // 추천 지역
              // -----------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '📍 추천 여행 지역',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      recommendedRegion,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      '당신의 여행 성향과 가장 잘 맞는 지역이에요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // -----------------------------
              // 코스 추천으로 이동
              // -----------------------------
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Center50Screen(
                          regionName: recommendedRegion,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    '코스 추천 넘어가기 →',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}