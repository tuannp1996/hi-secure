class App {
  final String id;
  final String name;
  final String url;

  App({required this.id, required this.name, required this.url});

  Map<String, String> toJson() => {
    'id': id,
    'name': name,
    'url': url,
  };

  factory App.fromJson(Map<String, dynamic> json) => App(
    id: json['id'] ?? json['code'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: json['name'] ?? '',
    url: json['url'] ?? '',
  );
}
