part of springbok_db_http;

class HttpCursor<T extends Model> extends StoreCursor<T> {

  HttpCursor(HttpStoreInstance<T> store, this.criteria): super(store);
  
  dynamic criteria;
  Map fields;
  int skip;
  int limit;
  Map sort;
  
  Future<T> next() => throw new UnsupportedError('Please use toList()');
  
  Future forEach(callback(T model))
    => toList().then((List<T> models) => models.forEach(callback));

  Future<List<T>> toList() => (store as HttpStoreInstance)
      .makeRequest('GET', { 'fields': fields, 'skip': skip, 'limit': limit, 'sort': sort }, null)
      .then((List<Map> result) => result == null ? null : result.map(store.toModel).toList(growable: false));
  
  Future close() => new Future.value();
}