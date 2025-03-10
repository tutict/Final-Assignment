class Category {
  /* 分组ID编号 */
  int? id;

  /* 分组名称 */
  String? name;

  Category();

  @override
  String toString() {
    return 'Category[id=$id, name=$name, ]';
  }

  Category.fromJson(Map<String, dynamic> json) {
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

  static List<Category> listFromJson(List<dynamic> json) {
    return json.map((value) => Category.fromJson(value)).toList();
  }

  static Map<String, Category> mapFromJson(Map<String, dynamic> json) {
    var map = <String, Category>{};
    if (json.isNotEmpty) {
      json.forEach(
          (String key, dynamic value) => map[key] = Category.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of Category-objects as value to a dart map
  static Map<String, List<Category>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<Category>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = Category.listFromJson(value);
      });
    }
    return map;
  }
}
