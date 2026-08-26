import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

// ================================================================
// SNOB 전국 관광지 데이터 수집
// ================================================================
//
// 목적
// ------------------------------------------------
// 전국 시군구별 중심관광지 데이터를 수집하고,
// 관광지 중분류별 개수를 집계한다.
//
// 이후 snob_substitutability.dart에서:
//
// (동일 카테고리 관광지 수 / 지역 전체 관광지 수) × 35
//
// 를 계산할 때 사용한다.
//
// 생성 파일
// ------------------------------------------------
// assets/data/snob_substitutability_data.json
//
// ================================================================


// ================================================================
// API 설정
// ================================================================

const String baseUrl =
    'https://apis.data.go.kr/B551011/LocgoHubTarService1';

const String serviceKey =
    'cbea666b85656aa336898b2d32bfee6f7d6fdad29e7c840109a41b9bf449c8a9';


// ================================================================
// 시군구 데이터
// ================================================================
//
// areaCd   : 시도 코드
// areaNm   : 시도명
// signguCd : 시군구 코드 (5자리 전체)
// signguNm : 시군구명
//
// ================================================================

final List<Map<String, String>> regions = [

  // ==============================================================
  // 서울특별시
  // ==============================================================

  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11110', 'signguNm': '종로구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11140', 'signguNm': '중구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11170', 'signguNm': '용산구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11200', 'signguNm': '성동구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11215', 'signguNm': '광진구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11230', 'signguNm': '동대문구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11260', 'signguNm': '중랑구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11290', 'signguNm': '성북구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11305', 'signguNm': '강북구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11320', 'signguNm': '도봉구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11350', 'signguNm': '노원구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11380', 'signguNm': '은평구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11410', 'signguNm': '서대문구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11440', 'signguNm': '마포구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11470', 'signguNm': '양천구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11500', 'signguNm': '강서구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11530', 'signguNm': '구로구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11545', 'signguNm': '금천구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11560', 'signguNm': '영등포구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11590', 'signguNm': '동작구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11620', 'signguNm': '관악구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11650', 'signguNm': '서초구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11680', 'signguNm': '강남구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11710', 'signguNm': '송파구'},
  {'areaCd': '11', 'areaNm': '서울특별시', 'signguCd': '11740', 'signguNm': '강동구'},


  // ==============================================================
  // 부산광역시
  // ==============================================================

  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26110', 'signguNm': '중구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26140', 'signguNm': '서구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26170', 'signguNm': '동구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26200', 'signguNm': '영도구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26230', 'signguNm': '부산진구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26260', 'signguNm': '동래구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26290', 'signguNm': '남구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26320', 'signguNm': '북구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26350', 'signguNm': '해운대구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26380', 'signguNm': '사하구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26410', 'signguNm': '금정구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26440', 'signguNm': '강서구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26470', 'signguNm': '연제구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26500', 'signguNm': '수영구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26530', 'signguNm': '사상구'},
  {'areaCd': '26', 'areaNm': '부산광역시', 'signguCd': '26710', 'signguNm': '기장군'},


  // ==============================================================
  // 대구광역시
  // ==============================================================

  {'areaCd': '27', 'areaNm': '대구광역시', 'signguCd': '27110', 'signguNm': '중구'},
  {'areaCd': '27', 'areaNm': '대구광역시', 'signguCd': '27140', 'signguNm': '동구'},
  {'areaCd': '27', 'areaNm': '대구광역시', 'signguCd': '27170', 'signguNm': '서구'},
  {'areaCd': '27', 'areaNm': '대구광역시', 'signguCd': '27200', 'signguNm': '남구'},
  {'areaCd': '27', 'areaNm': '대구광역시', 'signguCd': '27230', 'signguNm': '북구'},
  {'areaCd': '27', 'areaNm': '대구광역시', 'signguCd': '27260', 'signguNm': '수성구'},
  {'areaCd': '27', 'areaNm': '대구광역시', 'signguCd': '27290', 'signguNm': '달서구'},
  {'areaCd': '27', 'areaNm': '대구광역시', 'signguCd': '27710', 'signguNm': '달성군'},
  {'areaCd': '27', 'areaNm': '대구광역시', 'signguCd': '27720', 'signguNm': '군위군'},


  // ==============================================================
  // 인천광역시
  // ==============================================================

  {'areaCd': '28', 'areaNm': '인천광역시', 'signguCd': '28110', 'signguNm': '중구'},
  {'areaCd': '28', 'areaNm': '인천광역시', 'signguCd': '28140', 'signguNm': '동구'},
  {'areaCd': '28', 'areaNm': '인천광역시', 'signguCd': '28177', 'signguNm': '미추홀구'},
  {'areaCd': '28', 'areaNm': '인천광역시', 'signguCd': '28185', 'signguNm': '연수구'},
  {'areaCd': '28', 'areaNm': '인천광역시', 'signguCd': '28200', 'signguNm': '남동구'},
  {'areaCd': '28', 'areaNm': '인천광역시', 'signguCd': '28237', 'signguNm': '부평구'},
  {'areaCd': '28', 'areaNm': '인천광역시', 'signguCd': '28245', 'signguNm': '계양구'},
  {'areaCd': '28', 'areaNm': '인천광역시', 'signguCd': '28260', 'signguNm': '서구'},
  {'areaCd': '28', 'areaNm': '인천광역시', 'signguCd': '28710', 'signguNm': '강화군'},
  {'areaCd': '28', 'areaNm': '인천광역시', 'signguCd': '28720', 'signguNm': '옹진군'},


  // ==============================================================
  // 광주광역시
  // ==============================================================

  {'areaCd': '29', 'areaNm': '광주광역시', 'signguCd': '29110', 'signguNm': '동구'},
  {'areaCd': '29', 'areaNm': '광주광역시', 'signguCd': '29140', 'signguNm': '서구'},
  {'areaCd': '29', 'areaNm': '광주광역시', 'signguCd': '29155', 'signguNm': '남구'},
  {'areaCd': '29', 'areaNm': '광주광역시', 'signguCd': '29170', 'signguNm': '북구'},
  {'areaCd': '29', 'areaNm': '광주광역시', 'signguCd': '29200', 'signguNm': '광산구'},


  // ==============================================================
  // 대전광역시
  // ==============================================================

  {'areaCd': '30', 'areaNm': '대전광역시', 'signguCd': '30110', 'signguNm': '동구'},
  {'areaCd': '30', 'areaNm': '대전광역시', 'signguCd': '30140', 'signguNm': '중구'},
  {'areaCd': '30', 'areaNm': '대전광역시', 'signguCd': '30170', 'signguNm': '서구'},
  {'areaCd': '30', 'areaNm': '대전광역시', 'signguCd': '30200', 'signguNm': '유성구'},
  {'areaCd': '30', 'areaNm': '대전광역시', 'signguCd': '30230', 'signguNm': '대덕구'},


  // ==============================================================
  // 울산광역시
  // ==============================================================

  {'areaCd': '31', 'areaNm': '울산광역시', 'signguCd': '31110', 'signguNm': '중구'},
  {'areaCd': '31', 'areaNm': '울산광역시', 'signguCd': '31140', 'signguNm': '남구'},
  {'areaCd': '31', 'areaNm': '울산광역시', 'signguCd': '31170', 'signguNm': '동구'},
  {'areaCd': '31', 'areaNm': '울산광역시', 'signguCd': '31200', 'signguNm': '북구'},
  {'areaCd': '31', 'areaNm': '울산광역시', 'signguCd': '31710', 'signguNm': '울주군'},


  // ==============================================================
  // 세종특별자치시
  // ==============================================================

  {'areaCd': '36', 'areaNm': '세종특별자치시', 'signguCd': '36110', 'signguNm': '세종특별자치시'},


  // ==============================================================
  // 경기도
  // ==============================================================

  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41111', 'signguNm': '수원시 장안구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41113', 'signguNm': '수원시 권선구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41115', 'signguNm': '수원시 팔달구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41117', 'signguNm': '수원시 영통구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41131', 'signguNm': '성남시 수정구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41133', 'signguNm': '성남시 중원구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41135', 'signguNm': '성남시 분당구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41150', 'signguNm': '의정부시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41171', 'signguNm': '안양시 만안구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41173', 'signguNm': '안양시 동안구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41192', 'signguNm': '부천시 원미구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41194', 'signguNm': '부천시 소사구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41196', 'signguNm': '부천시 오정구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41210', 'signguNm': '광명시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41220', 'signguNm': '평택시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41250', 'signguNm': '동두천시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41271', 'signguNm': '안산시 상록구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41273', 'signguNm': '안산시 단원구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41281', 'signguNm': '고양시 덕양구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41285', 'signguNm': '고양시 일산동구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41287', 'signguNm': '고양시 일산서구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41290', 'signguNm': '과천시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41310', 'signguNm': '구리시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41360', 'signguNm': '남양주시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41370', 'signguNm': '오산시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41390', 'signguNm': '시흥시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41410', 'signguNm': '군포시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41430', 'signguNm': '의왕시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41450', 'signguNm': '하남시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41461', 'signguNm': '용인시 처인구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41463', 'signguNm': '용인시 기흥구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41465', 'signguNm': '용인시 수지구'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41480', 'signguNm': '파주시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41500', 'signguNm': '이천시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41550', 'signguNm': '안성시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41570', 'signguNm': '김포시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41590', 'signguNm': '화성시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41610', 'signguNm': '광주시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41630', 'signguNm': '양주시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41650', 'signguNm': '포천시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41670', 'signguNm': '여주시'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41800', 'signguNm': '연천군'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41820', 'signguNm': '가평군'},
  {'areaCd': '41', 'areaNm': '경기도', 'signguCd': '41830', 'signguNm': '양평군'},


  // ==============================================================
  // 충청북도
  // ==============================================================

  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43111', 'signguNm': '청주시 상당구'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43112', 'signguNm': '청주시 서원구'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43113', 'signguNm': '청주시 흥덕구'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43114', 'signguNm': '청주시 청원구'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43130', 'signguNm': '충주시'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43150', 'signguNm': '제천시'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43720', 'signguNm': '보은군'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43730', 'signguNm': '옥천군'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43740', 'signguNm': '영동군'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43745', 'signguNm': '증평군'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43750', 'signguNm': '진천군'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43760', 'signguNm': '괴산군'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43770', 'signguNm': '음성군'},
  {'areaCd': '43', 'areaNm': '충청북도', 'signguCd': '43800', 'signguNm': '단양군'},


  // ==============================================================
  // 충청남도
  // ==============================================================

  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44131', 'signguNm': '천안시 동남구'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44133', 'signguNm': '천안시 서북구'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44150', 'signguNm': '공주시'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44180', 'signguNm': '보령시'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44200', 'signguNm': '아산시'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44210', 'signguNm': '서산시'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44230', 'signguNm': '논산시'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44250', 'signguNm': '계룡시'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44270', 'signguNm': '당진시'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44710', 'signguNm': '금산군'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44760', 'signguNm': '부여군'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44770', 'signguNm': '서천군'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44790', 'signguNm': '청양군'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44800', 'signguNm': '홍성군'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44810', 'signguNm': '예산군'},
  {'areaCd': '44', 'areaNm': '충청남도', 'signguCd': '44825', 'signguNm': '태안군'},


  // ==============================================================
  // 전라남도
  // ==============================================================

  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46110', 'signguNm': '목포시'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46130', 'signguNm': '여수시'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46150', 'signguNm': '순천시'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46170', 'signguNm': '나주시'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46230', 'signguNm': '광양시'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46710', 'signguNm': '담양군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46720', 'signguNm': '곡성군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46730', 'signguNm': '구례군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46770', 'signguNm': '고흥군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46780', 'signguNm': '보성군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46790', 'signguNm': '화순군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46800', 'signguNm': '장흥군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46810', 'signguNm': '강진군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46820', 'signguNm': '해남군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46830', 'signguNm': '영암군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46840', 'signguNm': '무안군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46860', 'signguNm': '함평군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46870', 'signguNm': '영광군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46880', 'signguNm': '장성군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46890', 'signguNm': '완도군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46900', 'signguNm': '진도군'},
  {'areaCd': '46', 'areaNm': '전라남도', 'signguCd': '46910', 'signguNm': '신안군'},


  // ==============================================================
  // 경상북도
  // ==============================================================

  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47111', 'signguNm': '포항시 남구'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47113', 'signguNm': '포항시 북구'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47130', 'signguNm': '경주시'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47150', 'signguNm': '김천시'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47170', 'signguNm': '안동시'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47190', 'signguNm': '구미시'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47210', 'signguNm': '영주시'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47230', 'signguNm': '영천시'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47250', 'signguNm': '상주시'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47280', 'signguNm': '문경시'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47290', 'signguNm': '경산시'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47730', 'signguNm': '의성군'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47750', 'signguNm': '청송군'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47760', 'signguNm': '영양군'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47770', 'signguNm': '영덕군'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47820', 'signguNm': '청도군'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47830', 'signguNm': '고령군'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47840', 'signguNm': '성주군'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47850', 'signguNm': '칠곡군'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47900', 'signguNm': '예천군'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47920', 'signguNm': '봉화군'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47930', 'signguNm': '울진군'},
  {'areaCd': '47', 'areaNm': '경상북도', 'signguCd': '47940', 'signguNm': '울릉군'},


  // ==============================================================
  // 경상남도
  // ==============================================================

  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48121', 'signguNm': '창원시 의창구'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48123', 'signguNm': '창원시 성산구'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48125', 'signguNm': '창원시 마산합포구'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48127', 'signguNm': '창원시 마산회원구'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48129', 'signguNm': '창원시 진해구'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48170', 'signguNm': '진주시'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48220', 'signguNm': '통영시'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48240', 'signguNm': '사천시'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48250', 'signguNm': '김해시'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48270', 'signguNm': '밀양시'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48310', 'signguNm': '거제시'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48330', 'signguNm': '양산시'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48720', 'signguNm': '의령군'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48730', 'signguNm': '함안군'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48740', 'signguNm': '창녕군'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48820', 'signguNm': '고성군'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48840', 'signguNm': '남해군'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48850', 'signguNm': '하동군'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48860', 'signguNm': '산청군'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48870', 'signguNm': '함양군'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48880', 'signguNm': '거창군'},
  {'areaCd': '48', 'areaNm': '경상남도', 'signguCd': '48890', 'signguNm': '합천군'},


  // ==============================================================
  // 제주특별자치도
  // ==============================================================

  {'areaCd': '50', 'areaNm': '제주특별자치도', 'signguCd': '50110', 'signguNm': '제주시'},
  {'areaCd': '50', 'areaNm': '제주특별자치도', 'signguCd': '50130', 'signguNm': '서귀포시'},


  // ==============================================================
  // 강원특별자치도
  // ==============================================================

  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51110', 'signguNm': '춘천시'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51130', 'signguNm': '원주시'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51150', 'signguNm': '강릉시'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51170', 'signguNm': '동해시'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51190', 'signguNm': '태백시'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51210', 'signguNm': '속초시'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51230', 'signguNm': '삼척시'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51720', 'signguNm': '홍천군'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51730', 'signguNm': '횡성군'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51750', 'signguNm': '영월군'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51760', 'signguNm': '평창군'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51770', 'signguNm': '정선군'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51780', 'signguNm': '철원군'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51790', 'signguNm': '화천군'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51800', 'signguNm': '양구군'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51810', 'signguNm': '인제군'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51820', 'signguNm': '고성군'},
  {'areaCd': '51', 'areaNm': '강원특별자치도', 'signguCd': '51830', 'signguNm': '양양군'},


  // ==============================================================
  // 전북특별자치도
  // ==============================================================

  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52111', 'signguNm': '전주시 완산구'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52113', 'signguNm': '전주시 덕진구'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52130', 'signguNm': '군산시'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52140', 'signguNm': '익산시'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52180', 'signguNm': '정읍시'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52190', 'signguNm': '남원시'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52210', 'signguNm': '김제시'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52710', 'signguNm': '완주군'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52720', 'signguNm': '진안군'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52730', 'signguNm': '무주군'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52740', 'signguNm': '장수군'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52750', 'signguNm': '임실군'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52770', 'signguNm': '순창군'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52790', 'signguNm': '고창군'},
  {'areaCd': '52', 'areaNm': '전북특별자치도', 'signguCd': '52800', 'signguNm': '부안군'},
];


// ================================================================
// 기준월
// ================================================================

String getBaseYm() {
  final now = DateTime.now();

  final targetDate = now.month == 1
      ? DateTime(now.year - 1, 12)
      : DateTime(now.year, now.month - 1);

  return '${targetDate.year}'
      '${targetDate.month.toString().padLeft(2, '0')}';
}


// ================================================================
// 관광지 API 호출
// ================================================================

Future<List<Map<String, dynamic>>> getTouristSpots({
  required String areaCd,
  required String signguCd,
  required String baseYm,
}) async {
  final uri = Uri.parse(
    '$baseUrl/areaBasedList1',
  ).replace(
    queryParameters: {
      'serviceKey': serviceKey,
      'pageNo': '1',

      // 지역의 전체 관광지를 가져오기 위해 충분히 크게 설정
      'numOfRows': '100',

      'MobileOS': 'ETC',
      'MobileApp': 'SNOB',

      'baseYm': baseYm,
      'areaCd': areaCd,
      'signguCd': signguCd,

      '_type': 'json',
    },
  );

  final response = await http.get(uri);

  print('STATUS CODE: ${response.statusCode}');

  if (response.statusCode != 200) {
    throw Exception(
      '관광지 API 호출 실패: ${response.statusCode}',
    );
  }

  final decoded = jsonDecode(response.body);

  final responseData = decoded['response'];

  if (responseData is! Map) {
    return [];
  }

  final body = responseData['body'];

  if (body is! Map) {
    return [];
  }

  final items = body['items'];

  if (items == null || items == '') {
    return [];
  }

  if (items is! Map) {
    return [];
  }

  final item = items['item'];

  if (item == null || item == '') {
    return [];
  }

  if (item is List) {
    return item
        .map(
          (e) => Map<String, dynamic>.from(e),
        )
        .toList();
  }

  if (item is Map) {
    return [
      Map<String, dynamic>.from(item),
    ];
  }

  return [];
}


// ================================================================
// 메인
// ================================================================

Future<void> main() async {
  print('');
  print('============================================================');
  print('SNOB 전국 관광지 데이터 수집');
  print('============================================================');

  final baseYm = getBaseYm();

  print('조회 기준월 : $baseYm');
  print('시군구 개수 : ${regions.length}');
  print('============================================================');


  // ==============================================================
  // 최종 데이터
  // ==============================================================

  final Map<String, dynamic> result = {};


  // ==============================================================
  // 전국 지역 순회
  // ==============================================================

  for (int i = 0; i < regions.length; i++) {
    final region = regions[i];

    final areaCd = region['areaCd']!;
    final areaNm = region['areaNm']!;
    final signguCd = region['signguCd']!;
    final signguNm = region['signguNm']!;

    print('');
    print('------------------------------------------------------------');
    print('[${i + 1}/${regions.length}] '
        '$areaNm / $signguNm');
    print('areaCd   : $areaCd');
    print('signguCd : $signguCd');
    print('------------------------------------------------------------');


    try {
      final spots = await getTouristSpots(
        areaCd: areaCd,
        signguCd: signguCd,
        baseYm: baseYm,
      );


      // ==========================================================
      // 숙박 제거
      // ==========================================================

      final filteredSpots = spots.where((spot) {
        return spot['hubCtgryLclsNm']?.toString() != '숙박';
      }).toList();


      if (filteredSpots.isEmpty) {
        print('관광지 없음');

        result[signguCd] = {
          'areaCd': areaCd,
          'areaNm': areaNm,
          'signguCd': signguCd,
          'signguNm': signguNm,
          'totalCount': 0,
          'categories': <String, int>{},
          'spots': [],
        };

        continue;
      }


      // ==========================================================
      // 중분류별 개수 집계
      // ==========================================================

      final Map<String, int> categoryCounts = {};

      final List<Map<String, dynamic>> spotList = [];


      for (final spot in filteredSpots) {
        final category =
            spot['hubCtgryMclsNm']?.toString();

        final spotCode =
            spot['hubTatsCd']?.toString();

        final spotName =
            spot['hubTatsNm']?.toString();


        if (category == null ||
            category.isEmpty) {
          continue;
        }


        categoryCounts[category] =
            (categoryCounts[category] ?? 0) + 1;


        spotList.add({
          'hubTatsCd': spotCode,
          'hubTatsNm': spotName,
          'hubCtgryMclsNm': category,
        });
      }


      // ==========================================================
      // 지역 데이터 저장
      // ==========================================================

      result[signguCd] = {
        'areaCd': areaCd,
        'areaNm': areaNm,
        'signguCd': signguCd,
        'signguNm': signguNm,

        // 지역 전체 관광지 수
        'totalCount': spotList.length,

        // 중분류별 관광지 수
        'categories': categoryCounts,

        // 관광지 목록
        'spots': spotList,
      };


      // ==========================================================
      // 콘솔 출력
      // ==========================================================

      print(
        '관광지 수 : ${spotList.length}',
      );

      print(
        '카테고리 수 : ${categoryCounts.length}',
      );

      print('카테고리별 개수:');

      categoryCounts.forEach((category, count) {
        print('  $category : $count');
      });


      // ==========================================================
      // API 과부하 방지
      // ==========================================================

      await Future.delayed(
        const Duration(milliseconds: 200),
      );

    } catch (e) {
      print('오류 발생: $e');

      result[signguCd] = {
        'areaCd': areaCd,
        'areaNm': areaNm,
        'signguCd': signguCd,
        'signguNm': signguNm,
        'totalCount': 0,
        'categories': <String, int>{},
        'spots': [],
        'error': e.toString(),
      };
    }
  }


  // ==============================================================
  // 저장 폴더 생성
  // ==============================================================

  final directory = Directory(
    'assets/data',
  );

  if (!directory.existsSync()) {
    directory.createSync(
      recursive: true,
    );
  }


  // ==============================================================
  // JSON 저장
  // ==============================================================

  final file = File(
    'assets/data/snob_substitutability_data.json',
  );


  final jsonString = const JsonEncoder.withIndent(
    '  ',
  ).convert({
    'baseYm': baseYm,
    'regionCount': result.length,
    'regions': result,
  });


  await file.writeAsString(
    jsonString,
    encoding: utf8,
  );


  // ==============================================================
  // 완료
  // ==============================================================

  print('');
  print('============================================================');
  print('SNOB 전국 관광지 데이터 수집 완료');
  print('============================================================');

  print('전체 시군구 : ${regions.length}');
  print('저장된 지역 : ${result.length}');
  print('');
  print('생성 파일:');
  print(file.path);
  print('============================================================');
}