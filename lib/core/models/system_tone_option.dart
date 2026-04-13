class SystemToneOption {
  final String title;
  final String uri;

  const SystemToneOption({
    required this.title,
    required this.uri,
  });

  factory SystemToneOption.fromMap(Map<dynamic, dynamic> map) {
    return SystemToneOption(
      title: (map['title'] ?? '').toString(),
      uri: (map['uri'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'uri': uri,
    };
  }

  @override
  String toString() {
    return 'SystemToneOption(title: $title, uri: $uri)';
  }

  @override
  bool operator ==(Object other) {
    return other is SystemToneOption && other.uri == uri;
  }

  @override
  int get hashCode => uri.hashCode;
}