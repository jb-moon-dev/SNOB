class CourseItem {
  final String contentId;

  final String title;

  final String address;

  final String areaCode;

  final String sigunguCode;

  final double mapX;

  final double mapY;

  const CourseItem({
    required this.contentId,
    required this.title,
    required this.address,
    required this.areaCode,
    required this.sigunguCode,
    required this.mapX,
    required this.mapY,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      contentId: json["contentid"]?.toString() ?? "",
      title: json["title"]?.toString() ?? "",
      address: json["addr1"]?.toString() ?? "",
      areaCode: json["areacode"]?.toString() ?? "",
      sigunguCode: json["sigungucode"]?.toString() ?? "",
      mapX: double.tryParse(json["mapx"]?.toString() ?? "0") ?? 0,
      mapY: double.tryParse(json["mapy"]?.toString() ?? "0") ?? 0,
    );
  }
}