class Tag {
  /* 标签ID编号 */
  int? id;

  /* 标签名称 */
  String? name;

  Tag();

  @override
  String toString() {
    return 'Tag[id=$id, name=$name, ]';
  }

  Tag.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (id != null) {
      json['id'] = id;
    }
    if (name != null) {
      json['name'] = name;
    }
    return json;
  }

  static List<Tag> listFromJson(List<dynamic> json) {
    return json.map((value) => Tag.fromJson(value)).toList();
  }

  static Map<String, Tag> mapFromJson(Map<String, dynamic> json) {
    var map = <String, Tag>{};
    if (json.isNotEmpty) {
      json.forEach(
          (String key, dynamic value) => map[key] = Tag.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of Tag-objects as value to a dart map
  static Map<String, List<Tag>> mapListFromJson(Map<String, dynamic> json) {
    var map = <String, List<Tag>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = Tag.listFromJson(value);
      });
    }
    return map;
  }
}
