part of springbok_db_http;

class HttpStoreCriteria extends StoreCriteria {
  Map _criteria = {};
  
  fromMap(Map map) => _criteria = map;
  
  toJson() => _criteria;
}