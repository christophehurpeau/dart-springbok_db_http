library springbok_db_http;

import 'dart:html';
import 'dart:async';
import 'dart:mirrors';
import 'dart:convert' show JSON;

import 'package:springbok_db/springbok_db.dart';
export 'package:springbok_db/springbok_db.dart';

part 'src/cursor.dart';

springbokDbMongoInit() {
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
  
  Future makeRequest(String method, dynamic data) {
    return HttpRequest.request('${store.uri}/${model$.storeKey}',
        method: method,
        responseType: 'json',
        sendData: JSON.encode(data))
      .then((HttpRequest request) {
        if (request.status != 200) {
          throw new Exception('Status != 200: ${request.status} ${request.statusText} - ${request.responseText}');
        }
        return JSON.decode(request.responseText);
      });
    
  }
  
  Future<HttpCursor<T>> cursor([criteria])
    => new Future.value(new HttpCursor(this, criteria));
  Future<int> count([criteria]) => makeRequest('GET', { count: true, criteria: criteria });
  Future<List> distinct(String field, [criteria])
    => makeRequest('get', { distinct: field, criteria: criteria });

  
  Future insert(Map values)
    => makeRequest('PUT', [ false, values ]);
  Future insertAll(List<Map> values)
    => makeRequest('PUT', [ false, values ]);

  Future update(criteria, Map values)
    => makeRequest('POST', [ true, criteria, values ]);
  Future updateOne(criteria, Map values) 
    => makeRequest('POST', [ false, criteria, values ]);
  
  Future save(Map values)
  => makeRequest('PUT', [ true, values ]);
  
  Future remove(criteria)
    => makeRequest('DELETE', [ true, criteria ]);
  Future removeOne(criteria)
    => makeRequest('DELETE', [ false, criteria ]);
  
}

