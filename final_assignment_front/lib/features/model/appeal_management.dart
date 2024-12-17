class AppealManagement {
  /* 使用@TableId标记主键字段，类型为 AUTO 自增 */
  int? appealId;

  int? offenseId;

  /* 上诉人姓名，数据库字段名为\"appellant_name\" */
  String? appellantName;

  /* 身份证号码，数据库字段名为\"id_card_number\" */
  String? idCardNumber;

  /* 联系电话，数据库字段名为\"contact_number\" */
  String? contactNumber;

  /* 上诉原因，数据库字段名为\"appeal_reason\" */
  String? appealReason;

  /* 上诉时间，使用LocalDateTime存储，数据库字段名为\"appeal_time\" */
  String? appealTime;

  /* 处理状态，数据库字段名为\"process_status\" */
  String? processStatus;

  /* 处理结果，数据库字段名为\"process_result\" */
  String? processResult;

  AppealManagement();

  @override
  String toString() {
    return 'AppealManagement[appealId=$appealId, offenseId=$offenseId, appellantName=$appellantName, idCardNumber=$idCardNumber, contactNumber=$contactNumber, appealReason=$appealReason, appealTime=$appealTime, processStatus=$processStatus, processResult=$processResult, ]';
  }

  AppealManagement.fromJson(Map<String, dynamic> json) {
    appealId = json['appealId'];
    offenseId = json['offenseId'];
    appellantName = json['appellantName'];
    idCardNumber = json['idCardNumber'];
    contactNumber = json['contactNumber'];
    appealReason = json['appealReason'];
    appealTime = json['appealTime'];
    processStatus = json['processStatus'];
    processResult = json['processResult'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (appealId != null) {
      json['appealId'] = appealId;
    }
    if (offenseId != null) {
      json['offenseId'] = offenseId;
    }
    if (appellantName != null) {
      json['appellantName'] = appellantName;
    }
    if (idCardNumber != null) {
      json['idCardNumber'] = idCardNumber;
    }
    json['contactNumber'] = contactNumber;
    if (appealReason != null) {
      json['appealReason'] = appealReason;
    }
    if (appealTime != null) {
      json['appealTime'] = appealTime;
    }
    if (processStatus != null) {
      json['processStatus'] = processStatus;
    }
    if (processResult != null) {
      json['processResult'] = processResult;
    }
    return json;
  }

  static List<AppealManagement> listFromJson(List<dynamic> json) {
    return json.map((value) => AppealManagement.fromJson(value)).toList();
  }

  static Map<String, AppealManagement> mapFromJson(Map<String, dynamic> json) {
    var map = <String, AppealManagement>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) =>
          map[key] = AppealManagement.fromJson(value));
    }
    return map;
  }

  // maps a json object with a list of AppealManagement-objects as value to a dart map
  static Map<String, List<AppealManagement>> mapListFromJson(
      Map<String, dynamic> json) {
    var map = <String, List<AppealManagement>>{};
    if (json.isNotEmpty) {
      json.forEach((String key, dynamic value) {
        map[key] = AppealManagement.listFromJson(value);
      });
    }
    return map;
  }
}
