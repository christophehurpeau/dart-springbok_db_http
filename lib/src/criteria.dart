part of springbok_db_http;

class HttpStoreCriteria extends StoreCriteria {
  final Model$ _model$;
  
  HttpStoreCriteria(this._model$);
  
  Map criteria = {};
  
  fromMap(Map map) => criteria = map;

  toJson() => _model$.dataToStoreData(criteria);
}