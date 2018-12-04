import UIKit
import RxSwift

struct WSResponse {
    var raw : Data?
    var response:HTTPURLResponse
}

class http: NSObject {
    var headers: [String:String] = [:]
    var method: String
    var url: String
    var body : Data?
    var retryCount: Int = 3
    var retryInterval: Double = 5.0 //Seconds
    
    init(method:String, url:String) {
        self.method = method
        self.url = url
    }
    
    class func get(url:String) -> http {
        return http(method: "GET", url: url)
    }
    
    class func post(url:String) -> http {
        return http(method: "POST", url: url)
    }

    class func post<T : Encodable>(url:String, body: T) -> http {
        return post(url: url).withBody(body)
    }

    class func put(url:String) -> http {
        return http(method: "PUT", url: url)
    }
    
    class func put<T : Encodable>(url:String, body: T) -> http {
        return put(url: url).withBody(body)
    }

    class func delete(url:String) -> http {
        return http(method: "DELETE", url: url)
    }

    func withHeader(name: String, value: String) -> http {
        headers[name] = value
        
        return self
    }

    func withBody<T : Encodable>(_ body: T) -> http {
        let encoder = JSONEncoder()
        self.body = try? encoder.encode(body)
        
        return self
    }

    func withRetryCount(_ retryCount: Int) -> http {
        self.retryCount = retryCount
        
        return self
    }
    
    func withRetryInterval(_ retryInterval: Double) -> http {
        self.retryInterval = retryInterval
        
        return self
    }
    
    func execute<T : Decodable>() -> Observable<T> {
        return execute().map({ (r:WSResponse) -> T in
            let decoder = JSONDecoder()
            let obj : T = try decoder.decode(T.self, from: r.raw!)
            
            return obj
        })
    }
 
    func execute() -> Observable<WSResponse> {
        let _url = URL(string:
            url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)!
        
        NSLog("Executing %@ at: %@", method, url)
        
        let session = URLSession.shared
        let request = NSMutableURLRequest(url: _url, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 100)
        
        request.httpMethod = method
        
        //Setup accept header
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        if let bodyData = body {
            request.httpBody = bodyData
            
            //Setup content type to JSON
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        for (headerName, headerValue) in headers {
            request.addValue(headerValue, forHTTPHeaderField: headerName)
        }
        
        var observable = Observable<WSResponse>.create({ (observer) -> Disposable in
            let task = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
                if (error == nil) {
                    let httpsResponse = response as! HTTPURLResponse
                    
                    if (httpsResponse.statusCode < 400) {
                        observer.on(.next(WSResponse(raw: data, response:httpsResponse)))
                    } else {
                        observer.on(.error(NSError(domain: "WS", code: httpsResponse.statusCode, userInfo: ["message" :"Invalid status code: \(httpsResponse.statusCode)"])))
                    }
                } else {
                    observer.on(.error(error!))
                }
                
                observer.on(.completed)
            }
            
            task.resume()
            
            return Disposables.create()
        })
        
        //Retry GET requests
        if method == "GET" && retryCount > 0 {
            observable = observable.retryWhen({ errObs -> Observable<Int> in
                var _retryCount = 0
                
                return Observable<Int>.interval(self.retryInterval, scheduler: SerialDispatchQueueScheduler(qos: .default))
                    .flatMap({ (counter:Int) -> Observable<Int> in
                        _retryCount += 1
                        
                        if (_retryCount > self.retryCount) {
                            return Observable<Int>.error(NSError(domain: "RxHTTP", code: 0, userInfo: ["message" : "Maximum retry count reached"]))
                        }
                        
                        return Observable<Int>.of(counter)
                    })
            })
        }
        
        //Deliver the result on the main thread
        return observable.observeOn(MainScheduler.instance)
    }
}
