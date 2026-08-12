import 'course_item.dart';

class CourseResult {
  final String regionName;

  final List<CourseItem> course;

  const CourseResult({
    required this.regionName,
    required this.course,
  });

  bool get isEmpty => course.isEmpty;

  int get length => course.length;
}