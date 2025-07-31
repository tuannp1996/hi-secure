class Account {
  final String app;
  final String username;
  final String password;

  Account({required this.app, required this.username, required this.password});

  Map<String, String> toJson() => {
    'app': app,
    'username': username,
    'password': password,
  };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    app: json['app'],
    username: json['username'],
    password: json['password'],
  );
}
