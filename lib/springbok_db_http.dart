library springbok_db_http;

import 'dart:html';
import 'dart:async';
import 'dart:mirrors';
import 'dart:convert' show JSON;

import 'package:springbok_db/springbok_db.dart';
export 'package:springbok_db/springbok_db.dart';

part 'src/cursor.dart';
part 'src/criteria.dart';

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
  static final Map _converterRules = {
    reflectClass(Model): const ModelToMapRule(),
  };
  
  final HttpStore store;
  
  HttpStoreInstance(HttpStore store, Model$<T> model$):
    super(model$),
    this.store = store;
  
  Map get converterRules => _converterRules;
  
  StoreCriteria newCriteria() => new HttpStoreCriteria();

  T toModel(Map result) => result == null ? null : model$.mapToInstance(result);
  Map instanceToStoreMapResult(Map result) => model$.instanceToMap(result);
  
  Future makeRequest(String method, Map params, dynamic data) {
    print(params);
    if (params != null) {
      params.forEach((k, v){
        if (v != null) {
          try{
            params[k] = JSON.encode(v);
          }catch(e){
            throw new Exception('Unable to encode "$k": $e (value= $v)');
          }
        }
      });
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
  
  Future<HttpCursor<T>> cursor([StoreCriteria criteria])
    => new Future.value(new HttpCursor(this, criteria));
  Future<int> count([StoreCriteria criteria]) => makeRequest('GET', { 'count': true, 'criteria': criteria }, null);
  Future<List> distinct(String field, [StoreCriteria criteria])
    => makeRequest('get', { 'distinct': field, 'criteria': criteria }, null);

  
  Future insert(Map values)
    => makeRequest('PUT', null, [ false, values ]);
  Future insertAll(List<Map> values)
    => makeRequest('PUT', null, [ false, values ]);

  Future update(StoreCriteria criteria, Map values)
    => makeRequest('POST', null, [ true, criteria, values ]);
  Future updateOne(StoreCriteria criteria, Map values) 
    => makeRequest('POST', null, [ false, criteria, values ]);
  
  Future save(Map values)
  => makeRequest('PUT', null, [ true, values ]);
  
  Future remove(StoreCriteria criteria)
    => makeRequest('DELETE', null, [ true, criteria ]);
  Future removeOne(StoreCriteria criteria)
    => makeRequest('DELETE', null, [ false, criteria ]);
  
}

