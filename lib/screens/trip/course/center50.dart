import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'result_screen.dart';

/// ============================================================
/// CENTER 50
/// ============================================================
///
/// 역할
/// 1. 관광지 CSV 로드
/// 2. 혼잡도 JSON 로드
/// 3. 실제 혼잡도 JSON에 존재하는 지역을 canonical로 사용
/// 4. 추천 지역명을 canonical 지역으로 변환
/// 5. 관광지 CSV의 지역명도 같은 canonical 기준으로 변환
/// 6. 실제 혼잡도 데이터가 존재하는 관광지만 선별
/// 7. 집중률 낮은 순으로 정렬
/// 8. 최대 50개 전달
///
/// 핵심
/// - canonical 지역은 snob_concentration.json에 실제 존재하는 지역
/// - 210개 혼잡도 지역을 코드에 직접 하드코딩하지 않음
/// - 관광지 CSV의 지역명도 canonical 기준으로 변환
/// - 혼잡도 데이터가 없는 관광지는 제외
/// - concentration 50.0 fallback 없음
/// - 무거운 파싱/매칭은 compute() isolate에서 처리
/// - 동일 지역 재진입 시 최종 결과 캐시
/// ============================================================

class Center50Screen extends StatefulWidget {
  final String regionName;

  const Center50Screen({
    super.key,
    required this.regionName,
  });

  @override
  State<Center50Screen> createState() => _Center50ScreenState();
}

class _Center50ScreenState extends State<Center50Screen> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _spots = [];

  String _canonicalRegionName = '';

  /// ------------------------------------------------------------
  /// 원본 asset 캐시
  /// ------------------------------------------------------------

  static String? _cachedCsvText;
  static String? _cachedConcentrationText;

  /// ------------------------------------------------------------
  /// 최종 Center50 결과 캐시
  /// ------------------------------------------------------------

  static final Map<String, Map<String, dynamic>> _resultCache = {};

  @override
  void initState() {
    super.initState();
    _loadCenter50();
  }

  /// ============================================================
  /// CENTER 50 로드
  /// ============================================================

  Future<void> _loadCenter50() async {
    try {
      debugPrint('');
      debugPrint('==========================================');
      debugPrint('CENTER 50 시작');
      debugPrint('==========================================');

      debugPrint('추천 지역명: ${widget.regionName}');

      /// --------------------------------------------------------
      /// 1. 결과 캐시 확인
      /// --------------------------------------------------------

      final cacheKey = _normalizeCacheKey(widget.regionName);

      final cachedResult = _resultCache[cacheKey];

      if (cachedResult != null) {
        debugPrint('CENTER 50 캐시 사용');

        _applyResult(cachedResult);

        return;
      }

      /// --------------------------------------------------------
      /// 2. Asset 로드
      /// --------------------------------------------------------

      final csvText =
          _cachedCsvText ??
          await rootBundle.loadString(
            'assets/data/tourism_spots_protected.csv',
          );

      final concentrationText =
          _cachedConcentrationText ??
          await rootBundle.loadString(
            'assets/data/snob_concentration.json',
          );

      _cachedCsvText = csvText;
      _cachedConcentrationText = concentrationText;

      debugPrint('데이터 로드 완료');

      /// --------------------------------------------------------
      /// 3. 무거운 작업은 isolate에서 실행
      /// --------------------------------------------------------

      final result = await compute(
        _processCenter50,
        {
          'csvText': csvText,
          'concentrationText': concentrationText,
          'regionName': widget.regionName,
        },
      );

      /// --------------------------------------------------------
      /// 4. 결과 캐시
      /// --------------------------------------------------------

      _resultCache[cacheKey] = result;

      _applyResult(result);
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('==========================================');
      debugPrint('CENTER 50 오류');
      debugPrint('==========================================');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      debugPrint('');

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// ============================================================
  /// 결과 적용
  /// ============================================================

  void _applyResult(
    Map<String, dynamic> result,
  ) {
    final center50 =
        (result['spots'] as List)
            .map(
              (e) => Map<String, dynamic>.from(e),
            )
            .toList();

    final canonicalRegion =
        result['canonicalRegion']?.toString() ?? '';

    final totalCsv = result['totalCsv'] ?? 0;

    final totalConcentration =
        result['totalConcentration'] ?? 0;

    final regionSpotCount =
        result['regionSpotCount'] ?? 0;

    final nonAccommodationCount =
        result['nonAccommodationCount'] ?? 0;

    final exactMatchCount =
        result['exactMatchCount'] ?? 0;

    final variantMatchCount =
        result['variantMatchCount'] ?? 0;

    final noMatchCount =
        result['noMatchCount'] ?? 0;

    debugPrint(
      '전체 관광지 데이터: ${totalCsv}개',
    );

    debugPrint(
      '혼잡도 데이터: ${totalConcentration}개',
    );

    debugPrint(
      '추천 지역 → canonical 지역: '
      '${widget.regionName} → '
      '${canonicalRegion.isEmpty ? '변환 실패' : canonicalRegion}',
    );

    debugPrint(
      '지역 일치 관광지: '
      '${regionSpotCount}개',
    );

    debugPrint(
      '숙박 제외 후 관광지: '
      '${nonAccommodationCount}개',
    );

    debugPrint(
      '혼잡도 정확 매칭: '
      '${exactMatchCount}개',
    );

    debugPrint(
      '혼잡도 변형 매칭: '
      '${variantMatchCount}개',
    );

    debugPrint(
      '혼잡도 매칭 실패: '
      '${noMatchCount}개',
    );

    debugPrint(
      '혼잡도 매칭 성공: '
      '${center50.length}개',
    );

    if (canonicalRegion.isEmpty) {
      throw Exception(
        '추천 지역을 혼잡도 기준 지역으로 변환하지 못했습니다.\n'
        '추천 지역: ${widget.regionName}',
      );
    }

    if (center50.isEmpty) {
      throw Exception(
        '해당 지역에서 혼잡도 데이터가 있는 '
        '관광지를 찾을 수 없습니다.\n'
        '추천 지역: ${widget.regionName}\n'
        '혼잡도 기준 지역: $canonicalRegion',
      );
    }

    debugPrint('');
    debugPrint(
      'CENTER 50 최종 관광지: '
      '${center50.length}개',
    );

    for (int i = 0; i < center50.length; i++) {
      final spot = center50[i];

      debugPrint(
        '[${i + 1}] '
        '${spot['hubTatsNm']} | '
        '집중률=${spot['concentration']} | '
        '지역=${spot['regionName']}',
      );
    }

    debugPrint(
      '==========================================',
    );
    debugPrint('CENTER 50 완료');
    debugPrint(
      '==========================================',
    );
    debugPrint('');

    if (!mounted) return;

    setState(() {
      _spots = center50;
      _canonicalRegionName = canonicalRegion;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  /// ============================================================
  /// 캐시 key
  /// ============================================================

  String _normalizeCacheKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');
  }

  /// ============================================================
  /// CourseResultScreen 이동
  /// ============================================================

  void _goToCourseResult() {
    if (_spots.isEmpty) {
      return;
    }

    final canonicalRegion =
        _canonicalRegionName.isNotEmpty
            ? _canonicalRegionName
            : (_spots.first['regionName']?.toString() ??
                widget.regionName);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseResultScreen(
          spots: _spots,
          regionName: canonicalRegion,
        ),
      ),
    );
  }

  /// ============================================================
  /// BUILD
  /// ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('추천 관광지'),
      ),
      body: _buildBody(),
    );
  }

  /// ============================================================
  /// BODY
  /// ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                '관광지를 불러오지 못했습니다.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  _loadCenter50();
                },
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_spots.isEmpty) {
      return const Center(
        child: Text(
          '추천할 관광지가 없습니다.',
        ),
      );
    }

    final canonicalRegion =
        _canonicalRegionName.isNotEmpty
            ? _canonicalRegionName
            : widget.regionName;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$canonicalRegion\n'
                  '혼잡도 데이터가 있는 관광지 '
                  '${_spots.length}개',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _goToCourseResult,
                child: const Text('SNOB 분석'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _spots.length,
            itemBuilder: (context, index) {
              final spot = _spots[index];

              final title =
                  spot['hubTatsNm']?.toString() ?? '';

              final concentration =
                  (spot['concentration'] as num)
                      .toDouble();

              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    '${index + 1}',
                  ),
                ),
                title: Text(title),
                subtitle: Text(
                  '집중률 '
                  '${concentration.toStringAsFixed(2)}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// =================================================================
/// ISOLATE PROCESSOR
/// =================================================================

Map<String, dynamic> _processCenter50(
  Map<String, dynamic> input,
) {
  final csvText =
      input['csvText'] as String;

  final concentrationText =
      input['concentrationText'] as String;

  final requestedRegion =
      input['regionName'] as String;

  final processor =
      _Center50Processor();

  return processor.process(
    csvText: csvText,
    concentrationText: concentrationText,
    requestedRegion: requestedRegion,
  );
}

/// =================================================================
/// CENTER 50 PROCESSOR
/// =================================================================

class _Center50Processor {
  /// =============================================================
  /// 일반 문자열 정규화
  /// =============================================================

  String _normalizeName(String? value) {
    if (value == null) return '';

    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(
          RegExp(r'[\(\)\[\]\{\}]'),
          '',
        )
        .replaceAll('&', '')
        .replaceAll('·', '')
        .replaceAll(',', '')
        .replaceAll('.', '')
        .replaceAll('・', '')
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll('/', '');
  }

  /// =============================================================
  /// 지역 구성요소 정규화
  /// =============================================================
  ///
  /// 행정구역 명칭이 데이터 출처마다 다르게 들어오는 경우를
  /// canonical 비교 전에 동일한 이름으로 맞춘다.
  ///
  /// 예:
  ///
  /// 전북
  /// 전북특별자치도
  ///       ↓
  /// 전라북도
  ///
  /// 강원
  /// 강원특별자치도
  ///       ↓
  /// 강원도
  ///
  /// 충북
  ///       ↓
  /// 충청북도
  ///
  /// 경북
  ///       ↓
  /// 경상북도
  ///
  /// 중요:
  ///
  /// 전남광주통합특별시는 여기서
  /// 광주광역시 또는 전라남도로 강제 변환하지 않는다.
  ///
  /// 이 값은 아래 _convertToCanonicalRegion()에서
  /// 실제 canonical 후보를 보고 판단한다.
  /// =============================================================

  String _normalizeRegionPart(String? value) {
    if (value == null) return '';

    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');

    switch (normalized) {
      /// ----------------------------------------------------------
      /// 전북
      /// ----------------------------------------------------------

      case '전북':
      case '전북특별자치도':
        return '전라북도';

      /// ----------------------------------------------------------
      /// 전남
      /// ----------------------------------------------------------

      case '전남':
        return '전라남도';

      /// ----------------------------------------------------------
      /// 경북
      /// ----------------------------------------------------------

      case '경북':
        return '경상북도';

      /// ----------------------------------------------------------
      /// 경남
      /// ----------------------------------------------------------

      case '경남':
        return '경상남도';

      /// ----------------------------------------------------------
      /// 충북
      /// ----------------------------------------------------------

      case '충북':
        return '충청북도';

      /// ----------------------------------------------------------
      /// 충남
      /// ----------------------------------------------------------

      case '충남':
        return '충청남도';

      /// ----------------------------------------------------------
      /// 강원
      /// ----------------------------------------------------------

      case '강원':
      case '강원특별자치도':
        return '강원도';

      default:
        return normalized;
    }
  }

  /// =============================================================
  /// 지역명 파싱
  /// =============================================================

  Map<String, String> _parseRegionName(
    String regionName,
  ) {
    final parts =
        regionName
            .trim()
            .split(RegExp(r'\s+'))
            .where(
              (e) => e.isNotEmpty,
            )
            .toList();

    if (parts.isEmpty) {
      return {
        'sido': '',
        'sigungu': '',
      };
    }

    if (parts.length == 1) {
      return {
        'sido': parts.first,
        'sigungu': '',
      };
    }

    return {
      'sido': parts.first,
      'sigungu':
          parts.sublist(1).join(' '),
    };
  }

  /// =============================================================
  /// 지역 key
  /// =============================================================

  String _regionKey({
    required String sido,
    required String sigungu,
  }) {
    return '${_normalizeRegionPart(sido)}|'
        '${_normalizeRegionPart(sigungu)}';
  }

  /// =============================================================
  /// CSV 한 줄 파싱
  /// =============================================================

  List<String> _parseCsvLine(
    String line,
  ) {
    final result = <String>[];
    final buffer = StringBuffer();

    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (
          char == ',' &&
          !insideQuotes) {
        result.add(
          buffer.toString(),
        );
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    result.add(
      buffer.toString(),
    );

    return result.map((e) {
      var value = e.trim();

      if (value.startsWith('"') &&
          value.endsWith('"') &&
          value.length >= 2) {
        value = value.substring(
          1,
          value.length - 1,
        );
      }

      return value;
    }).toList();
  }

  /// =============================================================
  /// CSV 파싱
  /// =============================================================

  List<Map<String, dynamic>> _parseCsv(
    String csvText,
  ) {
    final lines =
        const LineSplitter()
            .convert(csvText);

    if (lines.isEmpty) {
      throw Exception(
        '관광지 CSV가 비어 있습니다.',
      );
    }

    final headers =
        _parseCsvLine(lines.first);

    final rows =
        <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final line =
          lines[i].trim();

      if (line.isEmpty) {
        continue;
      }

      final values =
          _parseCsvLine(line);

      if (values.length !=
          headers.length) {
        continue;
      }

      final row =
          <String, dynamic>{};

      for (
        int j = 0;
        j < headers.length;
        j++
      ) {
        row[headers[j]] =
            values[j];
      }

      rows.add(row);
    }

    return rows;
  }

  /// =============================================================
  /// concentration JSON 파싱
  /// =============================================================

  List<Map<String, dynamic>>
      _parseConcentration(
    String jsonText,
  ) {
    final decoded =
        json.decode(jsonText);

    if (decoded
        is! Map<String, dynamic>) {
      throw Exception(
        '혼잡도 JSON 형식이 올바르지 않습니다.',
      );
    }

    final records =
        decoded['records'];

    if (records is! List) {
      throw Exception(
        '혼잡도 JSON에 records가 없습니다.',
      );
    }

    return records
        .whereType<Map>()
        .map(
          (e) => Map<String, dynamic>
              .from(e),
        )
        .toList();
  }

  /// =============================================================
  /// canonical 지역 정보 생성
  /// =============================================================

  List<Map<String, String>>
      _buildCanonicalRegions(
    List<Map<String, dynamic>>
        records,
  ) {
    final seen = <String>{};

    final result =
        <Map<String, String>>[];

    for (final record in records) {
      final sido =
          record['sido']
                  ?.toString()
                  .trim() ??
              '';

      final sigungu =
          record['sigungu']
                  ?.toString()
                  .trim() ??
              '';

      if (sido.isEmpty ||
          sigungu.isEmpty) {
        continue;
      }

      final key =
          _regionKey(
        sido: sido,
        sigungu: sigungu,
      );

      if (seen.contains(key)) {
        continue;
      }

      seen.add(key);

      result.add({
        'sido': sido,
        'sigungu': sigungu,
        'key': key,
      });
    }

    return result;
  }

  /// =============================================================
  /// canonical 지역 변환
  /// =============================================================

  String _convertToCanonicalRegion({
    required String regionName,
    required List<Map<String, String>>
        canonicalRegions,
  }) {
    final original =
        regionName.trim();

    if (original.isEmpty) {
      return '';
    }

    final parsed =
        _parseRegionName(original);

    final originalSido =
        parsed['sido'] ?? '';

    final originalSigungu =
        parsed['sigungu'] ?? '';

    if (originalSido.isEmpty ||
        originalSigungu.isEmpty) {
      return '';
    }

    final normalizedSido =
        _normalizeRegionPart(
      originalSido,
    );

    final normalizedSigungu =
        _normalizeRegionPart(
      originalSigungu,
    );

    /// ----------------------------------------------------------
    /// 0. 전남광주통합특별시 특수 처리
    /// ----------------------------------------------------------
    ///
    /// 절대로
    ///
    /// 전남광주통합특별시
    /// → 광주광역시
    ///
    /// 로 먼저 바꾸지 않는다.
    ///
    /// 시군구 이름과 실제 canonical 목록을 기준으로
    /// 광주 / 전남을 결정한다.
    /// ----------------------------------------------------------

    if (_isIntegratedJeonnamGwangju(
      normalizedSido,
    )) {
      final integratedResult =
          _convertIntegratedJeonnamGwangju(
        normalizedSigungu:
            normalizedSigungu,
        canonicalRegions:
            canonicalRegions,
      );

      if (integratedResult.isNotEmpty) {
        return integratedResult;
      }

      return '';
    }

    /// ----------------------------------------------------------
    /// 1. 완전 일치
    /// ----------------------------------------------------------

    final exactKey =
        _regionKey(
      sido: originalSido,
      sigungu: originalSigungu,
    );

    for (final candidate
        in canonicalRegions) {
      if (candidate['key'] ==
          exactKey) {
        return _canonicalDisplayName(
          candidate,
        );
      }
    }

    /// ----------------------------------------------------------
    /// 2. 시군구 이름이 정확히 같은 canonical 찾기
    /// ----------------------------------------------------------

    final sameSigunguCandidates =
        canonicalRegions
            .where(
              (candidate) {
                final candidateSigungu =
                    _normalizeRegionPart(
                  candidate['sigungu'],
                );

                return candidateSigungu ==
                    normalizedSigungu;
              },
            )
            .toList();

    /// ----------------------------------------------------------
    /// 2-1. 정확히 하나만 존재
    /// ----------------------------------------------------------

    if (sameSigunguCandidates.length ==
        1) {
      return _canonicalDisplayName(
        sameSigunguCandidates.first,
      );
    }

    /// ----------------------------------------------------------
    /// 2-2. 여러 개라면 원본 시도와 관련된 후보 우선
    /// ----------------------------------------------------------

    if (sameSigunguCandidates.length > 1) {
      final preferredCandidates =
          sameSigunguCandidates
              .where(
                (candidate) {
                  final candidateSido =
                      _normalizeRegionPart(
                    candidate['sido'],
                  );

                  return _isLikelySameAdministrativeArea(
                    normalizedSido,
                    candidateSido,
                  );
                },
              )
              .toList();

      if (preferredCandidates.length ==
          1) {
        return _canonicalDisplayName(
          preferredCandidates.first,
        );
      }

      /// --------------------------------------------------------
      /// 광주 통합 특별시 데이터
      /// --------------------------------------------------------

      if (_isIntegratedJeonnamGwangju(
          normalizedSido)) {
        final gwangjuCandidates =
            sameSigunguCandidates
                .where(
                  (candidate) =>
                      _normalizeRegionPart(
                        candidate['sido'],
                      ) ==
                      '광주광역시',
                )
                .toList();

        if (gwangjuCandidates.length ==
            1) {
          return _canonicalDisplayName(
            gwangjuCandidates.first,
          );
        }
      }
    }

    /// ----------------------------------------------------------
    /// 3. 같은 시도에서 상위 행정구역 찾기
    /// ----------------------------------------------------------

    final sameSidoCandidates =
        canonicalRegions
            .where(
              (candidate) {
                final candidateSido =
                    _normalizeRegionPart(
                  candidate['sido'],
                );

                return candidateSido ==
                    normalizedSido;
              },
            )
            .toList();

    Map<String, String>? bestCandidate;

    int bestLength = -1;

    for (final candidate
        in sameSidoCandidates) {
      final candidateSigungu =
          _normalizeRegionPart(
        candidate['sigungu'],
      );

      if (candidateSigungu.isEmpty) {
        continue;
      }

      /// --------------------------------------------------------
      /// canonical이 요청 지역의 앞부분인 경우
      ///
      /// 화성시병점구
      ///   ↓
      /// 화성시
      /// --------------------------------------------------------

      if (normalizedSigungu
          .startsWith(candidateSigungu)) {
        if (candidateSigungu.length >
            bestLength) {
          bestCandidate = candidate;
          bestLength =
              candidateSigungu.length;
        }

        continue;
      }

      /// --------------------------------------------------------
      /// 반대 방향도 일부 특이 데이터 대응
      /// --------------------------------------------------------

      if (normalizedSigungu
          .contains(candidateSigungu)) {
        if (candidateSigungu.length >
            bestLength) {
          bestCandidate = candidate;
          bestLength =
              candidateSigungu.length;
        }
      }
    }

    if (bestCandidate != null) {
      return _canonicalDisplayName(
        bestCandidate,
      );
    }

    /// ----------------------------------------------------------
    /// 4. 공백 단위로 하위 행정구역 제거
    /// ----------------------------------------------------------

    final parts =
        original
            .split(RegExp(r'\s+'))
            .where(
              (e) => e.isNotEmpty,
            )
            .toList();

    if (parts.length >= 3) {
      for (
        int end = parts.length - 1;
        end >= 2;
        end--
      ) {
        final candidateSigungu =
            parts
                .sublist(1, end)
                .join(' ');

        final candidateKey =
            _regionKey(
          sido: parts.first,
          sigungu:
              candidateSigungu,
        );

        for (final candidate
            in canonicalRegions) {
          if (candidate['key'] ==
              candidateKey) {
            return _canonicalDisplayName(
              candidate,
            );
          }
        }
      }
    }

    /// ----------------------------------------------------------
    /// 5. 실패
    /// ----------------------------------------------------------

    return '';
  }

  /// =============================================================
  /// 전남광주통합특별시 시군구 판별
  /// =============================================================

  bool _isGwangjuDistrict(
    String normalizedSigungu,
  ) {
    const districts = {
      '광산구',
      '남구',
      '동구',
      '북구',
      '서구',
    };

    return districts.contains(
      normalizedSigungu,
    );
  }

  /// =============================================================
  /// 전남광주통합특별시 변환
  /// =============================================================
  ///
  /// 예:
  ///
  /// 전남광주통합특별시 광산구
  /// → 광주광역시 광산구
  ///
  /// 전남광주통합특별시 남구
  /// → 광주광역시 남구
  ///
  /// 전남광주통합특별시 무안군
  /// → 전라남도 무안군
  ///
  /// 단,
  /// 실제 snob_concentration.json에 존재하는 canonical만
  /// 결과로 반환한다.
  /// =============================================================

  String _convertIntegratedJeonnamGwangju({
    required String normalizedSigungu,
    required List<Map<String, String>>
        canonicalRegions,
  }) {
    debugPrint(
      '통합 시도 변환 시작: '
      '시군구=$normalizedSigungu',
    );

    final candidates =
        canonicalRegions.where(
      (candidate) {
        final candidateSigungu =
            _normalizeRegionPart(
          candidate['sigungu'],
        );

        return candidateSigungu ==
            normalizedSigungu;
      },
    ).toList();

    debugPrint(
      '통합 시도 변환 후보: '
      '$normalizedSigungu → '
      '${candidates.map(
        (e) =>
            '${e['sido']} ${e['sigungu']}',
      ).join(', ')}',
    );

    if (candidates.isEmpty) {
      debugPrint(
        '통합 시도 변환 후보 없음: '
        '$normalizedSigungu',
      );

      return '';
    }

    /// ----------------------------------------------------------
    /// 광주 구역
    /// ----------------------------------------------------------

    if (_isGwangjuDistrict(
      normalizedSigungu,
    )) {
      final gwangjuCandidates =
          candidates.where(
        (candidate) {
          return _normalizeRegionPart(
                candidate['sido'],
              ) ==
              '광주광역시';
        },
      ).toList();

      if (gwangjuCandidates.length ==
          1) {
        final result =
            _canonicalDisplayName(
          gwangjuCandidates.first,
        );

        debugPrint(
          '통합 시도 → 광주광역시 변환: '
          '$result',
        );

        return result;
      }
    }

    /// ----------------------------------------------------------
    /// 전라남도 후보
    /// ----------------------------------------------------------

    final jeonnamCandidates =
        candidates.where(
      (candidate) {
        return _normalizeRegionPart(
              candidate['sido'],
            ) ==
            '전라남도';
      },
    ).toList();

    if (jeonnamCandidates.length ==
        1) {
      final result =
          _canonicalDisplayName(
        jeonnamCandidates.first,
      );

      debugPrint(
        '통합 시도 → 전라남도 변환: '
        '$result',
      );

      return result;
    }

    /// ----------------------------------------------------------
    /// 후보가 여러 개인 경우
    /// ----------------------------------------------------------

    if (candidates.length == 1) {
      final result =
          _canonicalDisplayName(
        candidates.first,
      );

      debugPrint(
        '통합 시도 → 유일 canonical 변환: '
        '$result',
      );

      return result;
    }

    debugPrint(
      '통합 시도 변환 후보가 모호하여 실패: '
      '$normalizedSigungu',
    );

    return '';
  }

  /// =============================================================
  /// canonical 표시명
  /// =============================================================

  String _canonicalDisplayName(
    Map<String, String> candidate,
  ) {
    final sido =
        candidate['sido'] ?? '';

    final sigungu =
        candidate['sigungu'] ?? '';

    return '$sido $sigungu'.trim();
  }

  /// =============================================================
  /// 통합 전남/광주 지역인지 확인
  /// =============================================================

  bool _isIntegratedJeonnamGwangju(
    String normalizedSido,
  ) {
    return normalizedSido ==
        '전남광주통합특별시';
  }

  /// =============================================================
  /// 시도 관련성 판단
  /// =============================================================

  bool _isLikelySameAdministrativeArea(
    String requestedSido,
    String candidateSido,
  ) {
    if (requestedSido ==
        candidateSido) {
      return true;
    }

    if (requestedSido ==
        '전남광주통합특별시') {
      return candidateSido ==
              '광주광역시' ||
          candidateSido ==
              '전라남도';
    }

    return false;
  }

  /// =============================================================
  /// concentration index
  /// =============================================================

  Map<String,
          Map<String,
              Map<String, dynamic>>>
      _buildConcentrationIndex(
    List<Map<String, dynamic>>
        records,
  ) {
    final index =
        <String,
            Map<String,
                Map<String, dynamic>>>{};

    for (final record in records) {
      final sido =
          record['sido']
                  ?.toString()
                  .trim() ??
              '';

      final sigungu =
          record['sigungu']
                  ?.toString()
                  .trim() ??
              '';

      final name =
          record['name']
                  ?.toString()
                  .trim() ??
              '';

      final concentration =
          record['concentration'];

      /// --------------------------------------------------------
      /// 필요한 값이 없는 record 제외
      /// --------------------------------------------------------

      if (sido.isEmpty ||
          sigungu.isEmpty ||
          name.isEmpty ||
          concentration == null) {
        continue;
      }

      final parsedConcentration =
          concentration is num
              ? concentration.toDouble()
              : double.tryParse(
                  concentration.toString(),
                );

      if (parsedConcentration == null) {
        continue;
      }

      final regionKey =
          _regionKey(
        sido: sido,
        sigungu: sigungu,
      );

      final nameKey =
          _normalizeName(name);

      if (nameKey.isEmpty) {
        continue;
      }

      index.putIfAbsent(
        regionKey,
        () =>
            <String,
                Map<String, dynamic>>{},
      );

      index[regionKey]!.putIfAbsent(
        nameKey,
        () => record,
      );
    }

    return index;
  }

  /// =============================================================
  /// 숙박 여부
  /// =============================================================

  bool _isAccommodation(
    Map<String, dynamic> spot,
  ) {
    final contentType =
        spot['contentTypeId']
                ?.toString() ??
            '';

    final title =
        spot['title']
                ?.toString()
                .toLowerCase() ??
            '';

    if (contentType == '32') {
      return true;
    }

    if (title.contains('호텔') ||
        title.contains('모텔') ||
        title.contains('펜션') ||
        title.contains('리조트') ||
        title.contains('게스트하우스')) {
      return true;
    }

    return false;
  }

  /// =============================================================
  /// 관광지 이름 매칭
  /// =============================================================

  Map<String, dynamic>?
      _findConcentrationRecord({
    required Map<String, dynamic>
        csvSpot,
    required Map<String,
            Map<String, dynamic>>
        regionRecords,
  }) {
    final title =
        csvSpot['title']
                ?.toString()
                .trim() ??
            '';

    if (title.isEmpty ||
        regionRecords.isEmpty) {
      return null;
    }

    final normalizedTitle =
        _normalizeName(title);

    /// ----------------------------------------------------------
    /// 1. 정확 매칭
    /// ----------------------------------------------------------

    final exact =
        regionRecords[normalizedTitle];

    if (exact != null) {
      return exact;
    }

    /// ----------------------------------------------------------
    /// 2. 변형 매칭
    /// ----------------------------------------------------------

    for (final entry
        in regionRecords.entries) {
      final concentrationName =
          entry.value['name']
                  ?.toString() ??
              '';

      final normalizedConcentrationName =
          entry.key;

      if (normalizedConcentrationName
              .isEmpty ||
          concentrationName.isEmpty) {
        continue;
      }

      if (normalizedTitle ==
          normalizedConcentrationName) {
        return entry.value;
      }

      if (normalizedTitle
              .contains(
            normalizedConcentrationName,
          ) ||
          normalizedConcentrationName
              .contains(
            normalizedTitle,
          )) {
        final shorter =
            normalizedTitle.length <
                    normalizedConcentrationName
                        .length
                ? normalizedTitle.length
                : normalizedConcentrationName
                    .length;

        if (shorter >= 4) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// =============================================================
  /// Spot 생성
  /// =============================================================

  Map<String, dynamic> _buildSpot({
    required Map<String, dynamic>
        csvSpot,
    required Map<String, dynamic>
        concentrationRecord,
    required String canonicalRegion,
  }) {
    final region =
        _parseRegionName(
      canonicalRegion,
    );

    final title =
        csvSpot['title']
                ?.toString() ??
            '';

    final contentId =
        csvSpot['contentId']
                ?.toString() ??
            '';

    final concentrationValue =
        concentrationRecord['concentration'];

    final concentration =
        concentrationValue is num
            ? concentrationValue.toDouble()
            : double.tryParse(
                concentrationValue
                        ?.toString() ??
                    '',
              );

    if (concentration == null) {
      throw Exception(
        '혼잡도 값이 없는 관광지: $title',
      );
    }

    final latitude =
        double.tryParse(
      csvSpot['latitude']
              ?.toString() ??
          '',
    );

    final longitude =
        double.tryParse(
      csvSpot['longitude']
              ?.toString() ??
          '',
    );

    return {
      /// --------------------------------------------------------
      /// 원본 CSV 정보
      /// --------------------------------------------------------

      ...csvSpot,

      /// --------------------------------------------------------
      /// canonical 지역
      /// --------------------------------------------------------

      'regionName':
          canonicalRegion,

      'areaNm':
          region['sido'] ?? '',

      'signguNm':
          region['sigungu'] ?? '',

      /// --------------------------------------------------------
      /// 관광지 정보
      /// --------------------------------------------------------

      'hubTatsCd':
          contentId,

      'hubTatsNm':
          title,

      'areaCd':
          csvSpot['lDongRegnCd']
                  ?.toString() ??
              '',

      'signguCd':
          csvSpot['lDongSignguCd']
                  ?.toString() ??
              '',

      'hubCtgryLclsNm':
          csvSpot['lclsSystm1']
                  ?.toString() ??
              '',

      'hubCtgryMclsNm':
          csvSpot['lclsSystm2']
                  ?.toString() ??
              '',

      'hubCtgrySclsNm':
          csvSpot['lclsSystm3']
                  ?.toString() ??
              '',

      'mapX':
          longitude,

      'mapY':
          latitude,

      'hubRank':
          0,

      /// --------------------------------------------------------
      /// 보호 관광지
      /// --------------------------------------------------------

      'is_protected':
          csvSpot['is_protected']
                      ?.toString() ==
                  'True' ||
              csvSpot['is_protected']
                      ?.toString() ==
                  'true',

      'protected_type':
          csvSpot['protected_type']
                  ?.toString() ??
              '',

      'protected_flag':
          csvSpot['protected_flag']
                  ?.toString() ??
              '0',

      /// --------------------------------------------------------
      /// 혼잡도
      /// --------------------------------------------------------

      'concentration':
          concentration,

      'concentrationName':
          concentrationRecord['name']
                  ?.toString() ??
              '',

      'concentrationSigunguCode':
          concentrationRecord[
                    'sigunguCode']
                  ?.toString() ??
              '',

      'concentrationDataCount':
          concentrationRecord[
                'dataCount'] ??
              0,
    };
  }

  /// =============================================================
  /// 실제 처리
  /// =============================================================

  Map<String, dynamic> process({
    required String csvText,
    required String concentrationText,
    required String requestedRegion,
  }) {
    /// ----------------------------------------------------------
    /// 1. CSV / JSON 파싱
    /// ----------------------------------------------------------

    final csvSpots =
        _parseCsv(csvText);

    final concentrationRecords =
        _parseConcentration(
      concentrationText,
    );

    /// ----------------------------------------------------------
    /// 2. 실제 혼잡도 JSON에 존재하는 canonical 지역 생성
    /// ----------------------------------------------------------

    final canonicalRegions =
        _buildCanonicalRegions(
      concentrationRecords,
    );

    /// ----------------------------------------------------------
    /// 3. 추천 지역 → canonical 지역
    /// ----------------------------------------------------------

    final canonicalRegion =
        _convertToCanonicalRegion(
      regionName:
          requestedRegion,
      canonicalRegions:
          canonicalRegions,
    );

    debugPrint(
      '지역 canonical 변환: '
      '$requestedRegion → '
      '${canonicalRegion.isEmpty ? '실패' : canonicalRegion}',
    );

    /// ----------------------------------------------------------
    /// canonical 변환 실패
    /// ----------------------------------------------------------

    if (canonicalRegion.isEmpty) {
      return {
        'canonicalRegion': '',
        'totalCsv':
            csvSpots.length,
        'totalConcentration':
            concentrationRecords.length,
        'regionSpotCount':
            0,
        'nonAccommodationCount':
            0,
        'exactMatchCount':
            0,
        'variantMatchCount':
            0,
        'noMatchCount':
            0,
        'spots':
            <Map<String, dynamic>>[],
      };
    }

    /// ----------------------------------------------------------
    /// 4. concentration index
    /// ----------------------------------------------------------

    final concentrationIndex =
        _buildConcentrationIndex(
      concentrationRecords,
    );

    /// ----------------------------------------------------------
    /// canonical region key
    /// ----------------------------------------------------------

    final canonicalParsed =
        _parseRegionName(
      canonicalRegion,
    );

    final canonicalKey =
        _regionKey(
      sido:
          canonicalParsed['sido'] ??
              '',
      sigungu:
          canonicalParsed['sigungu'] ??
              '',
    );

    final canonicalRecords =
        concentrationIndex[
                canonicalKey] ??
            <
                String,
                Map<String, dynamic>
            >{};

    /// ----------------------------------------------------------
    /// 5. CSV 관광지를 canonical region 기준으로 필터
    /// ----------------------------------------------------------

    final regionSpots =
        <Map<String, dynamic>>[];

    for (final spot in csvSpots) {
      final csvRegion =
          spot['regionName']
                  ?.toString()
                  .trim() ??
              '';

      if (csvRegion.isEmpty) {
        continue;
      }

      final csvCanonical =
          _convertToCanonicalRegion(
        regionName:
            csvRegion,
        canonicalRegions:
            canonicalRegions,
      );

      if (csvCanonical ==
          canonicalRegion) {
        regionSpots.add(spot);
      }
    }

    /// ----------------------------------------------------------
    /// 6. 숙박 제외
    /// ----------------------------------------------------------

    final nonAccommodationSpots =
        <Map<String, dynamic>>[];

    for (final spot
        in regionSpots) {
      if (!_isAccommodation(spot)) {
        nonAccommodationSpots.add(
          spot,
        );
      }
    }

    /// ----------------------------------------------------------
    /// 7. 혼잡도 실제 매칭
    /// ----------------------------------------------------------

    final matchedSpots =
        <Map<String, dynamic>>[];

    int exactMatchCount = 0;
    int variantMatchCount = 0;
    int noMatchCount = 0;

    for (final csvSpot
        in nonAccommodationSpots) {
      final title =
          csvSpot['title']
                  ?.toString() ??
              '';

      final record =
          _findConcentrationRecord(
        csvSpot:
            csvSpot,
        regionRecords:
            canonicalRecords,
      );

      /// 혼잡도 데이터 없음
      if (record == null) {
        noMatchCount++;
        continue;
      }

      /// --------------------------------------------------------
      /// concentration 값 검증
      /// --------------------------------------------------------

      final concentrationValue =
          record['concentration'];

      final concentration =
          concentrationValue is num
              ? concentrationValue.toDouble()
              : double.tryParse(
                  concentrationValue
                          ?.toString() ??
                      '',
                );

      if (concentration == null) {
        noMatchCount++;
        continue;
      }

      /// --------------------------------------------------------
      /// 정확 / 변형 매칭 통계
      /// --------------------------------------------------------

      final concentrationName =
          record['name']
                  ?.toString() ??
              '';

      if (_normalizeName(title) ==
          _normalizeName(
            concentrationName,
          )) {
        exactMatchCount++;
      } else {
        variantMatchCount++;
      }

      /// --------------------------------------------------------
      /// Spot 생성
      /// --------------------------------------------------------

      final resultSpot =
          _buildSpot(
        csvSpot:
            csvSpot,
        concentrationRecord:
            record,
        canonicalRegion:
            canonicalRegion,
      );

      matchedSpots.add(
        resultSpot,
      );
    }

    /// ----------------------------------------------------------
    /// 8. 집중률 낮은 순 정렬
    /// ----------------------------------------------------------

    matchedSpots.sort(
      (a, b) {
        final aValue =
            (a['concentration'] as num)
                .toDouble();

        final bValue =
            (b['concentration'] as num)
                .toDouble();

        return aValue.compareTo(
          bValue,
        );
      },
    );

    /// ----------------------------------------------------------
    /// 9. TOP 50
    /// ----------------------------------------------------------

    final center50 =
        matchedSpots.length > 50
            ? matchedSpots
                .take(50)
                .toList()
            : matchedSpots;

    /// ----------------------------------------------------------
    /// 10. 결과
    /// ----------------------------------------------------------

    return {
      'canonicalRegion':
          canonicalRegion,

      'totalCsv':
          csvSpots.length,

      'totalConcentration':
          concentrationRecords.length,

      'regionSpotCount':
          regionSpots.length,

      'nonAccommodationCount':
          nonAccommodationSpots.length,

      'exactMatchCount':
          exactMatchCount,

      'variantMatchCount':
          variantMatchCount,

      'noMatchCount':
          noMatchCount,

      'spots':
          center50,
    };
  }
}

