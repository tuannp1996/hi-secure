class App {
  final String id;
  final String name;
  final String url;
  final String? packageName;

  App({required this.id, required this.name, required this.url, this.packageName,});

  Map<String, String> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'packageName': ?packageName,
  };

  factory App.fromJson(Map<String, dynamic> json) => App(
    id: json['id'] ?? json['code'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: json['name'] ?? '',
    url: json['url'] ?? '',
    packageName: json['packageName'] ?? '',
  );
}
