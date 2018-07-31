import UIKit
import RxSwift

struct WSResponse {
    var raw : Data?
    var response:HTTPURLResponse
}

class http: NSObject {
    class func get<T : Decodable>(url:String) -> Observable<T> {
        return execute(url: url, method: "GET", body: nil, headers: nil)
    }

    class func post<T_in : Encodable, T_out : Decodable>(url:String, body : T_in) -> Observable<T_out> {
        return execute(url: url, method: "POST", body: body)
    }
    
    class func put<T_in : Encodable, T_out : Decodable>(url:String, body : T_in) -> Observable<T_out> {
        return execute(url: url, method: "PUT", body: body)
    }
    
    class func execute<T_in : Encodable, T_out : Decodable>(url:String, method:String, body : T_in, headers: [String:String]? = nil) -> Observable<T_out> {
        let encoder = JSONEncoder()
        let bodyData = try? encoder.encode(body)
        
        return execute(url: url, method: method, body: bodyData, headers: headers)
    }
    
    class func execute<T : Decodable>(url:String, method:String, body : Data? = nil, headers: [String:String]? = nil) -> Observable<T> {
        return execute(url: url, method: method, body: body, headers: headers).map({ (r:WSResponse) -> T in
            let decoder = JSONDecoder()
            let obj : T = try decoder.decode(T.self, from: r.raw!)
            
            return obj
        })
    }
    
    class func execute(url:String, method:String, body : Data? = nil, headers: [String:String]? = nil) -> Observable<WSResponse> {
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
        
        if let headers = headers {
            for (headerName, headerValue) in headers {
                request.addValue(headerValue, forHTTPHeaderField: headerName)
            }
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
        
        if method == "GET" {
            observable = observable.retryWhen({ errObs -> Observable<Int> in
                var retryCount = 0
                
                return Observable<Int>.interval(5, scheduler: SerialDispatchQueueScheduler(qos: .default))
                    .flatMap({ (counter:Int) -> Observable<Int> in
                        retryCount += 1
                        
                        if (retryCount > 2) {
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
