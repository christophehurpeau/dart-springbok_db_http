library springbok_db_http;

import 'dart:html';
import 'dart:async';
import 'dart:mirrors';
import 'dart:convert' show JSON;

import 'package:springbok_db/springbok_db.dart';
export 'package:springbok_db/springbok_db.dart';

part 'src/cursor.dart';

springbokDbHttpInit() {
  Db.stringToStore['http'] = (Map config) => new HttpStore(config['uri']);
}

class HttpStore extends AbstractStore<HttpStoreInstance> {
  final String uri;
  
  HttpStore(String this.uri);
  
  Future init(Db db) {
    return new Future.value();
  }

  HttpStoreInstance instance(Model$ model$)
    => new HttpStoreInstance(this, model$);
}

class HttpStoreInstance<T extends Model> extends AbstractStoreInstance<T> {
  static final Converters _converter = new Converters({
    reflectClass(Model): const ModelConverter(), //Not the store version, because we send it to the server
    reflectClass(List): const ListConverter(),
  });
  
  final HttpStore store;
  
  HttpStoreInstance(HttpStore store, Model$<T> model$):
    super(model$),
    this.store = store;
  
  Converters get converter => _converter;
  
  T toModel(Map result) => result == null ? null : model$.createInstance(result);
  
  Future makeRequest(String method, Map params, dynamic data) {
    if (params != null) {
      params.forEach((k, v) => params[k] = JSON.encode(v));
    }
    
    var uri = new Uri(
      path: '${store.uri}/${model$.storeKey}',
      queryParameters: params
    );
    return HttpRequest.request(uri.toString(),
      method: method,
      //responseType: 'json',
      sendData: data == null ? null : JSON.encode(data))
    .then((HttpRequest request) {
      if (request.status != 200) {
        throw new Exception('Status != 200: ${request.status} ${request.statusText} - ${request.responseText}');
      }
      return JSON.decode(request.response);
    });
  }
  
  Future<HttpCursor<T>> cursor([criteria])
    => new Future.value(new HttpCursor(this, criteria));
  Future<int> count([criteria]) => makeRequest('GET', { 'count': true, 'criteria': criteria }, null);
  Future<List> distinct(String field, [criteria])
    => makeRequest('get', { 'distinct': field, 'criteria': criteria }, null);

  
  Future insert(Map values)
    => makeRequest('PUT', null, [ false, values ]);
  Future insertAll(List<Map> values)
    => makeRequest('PUT', null, [ false, values ]);

  Future update(criteria, Map values)
    => makeRequest('POST', null, [ true, criteria, values ]);
  Future updateOne(criteria, Map values) 
    => makeRequest('POST', null, [ false, criteria, values ]);
  
  Future save(Map values)
  => makeRequest('PUT', null, [ true, values ]);
  
  Future remove(criteria)
    => makeRequest('DELETE', null, [ true, criteria ]);
  Future removeOne(criteria)
    => makeRequest('DELETE', null, [ false, criteria ]);
  
}

