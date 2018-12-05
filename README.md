## Introduction
RxHTTP is a HTTP client library written in Swift. It uses RxSwift for asynchronous programming.

## Main Features

- Automatic encoding and decoding of ojects to JSON. This takes advantage of the Swift generics type system to simplify coding.
- Use ``Observable`` from RxSwift project.
- A very thin layer over the native ``URLSession`` API.
- Built in retry for GET requests.

## Using RxHTTP In Your App

The code base is so small that there is no need to package it in a framework. Just do this:

- Add dependency for ``RxSwift`` to your project.
- Add ``http.swift`` file to your project.

## Example Usages

### Simple GET

```swift
import RxSwift

struct BlogPost : Decodable {
    var id: Int
    var userId: Int
    var title: String
    var body: String
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let _ = http.get(url: "https://jsonplaceholder.typicode.com/posts/1")
            .execute()
            .subscribe(
                onNext: {(p: BlogPost) in print("Title: \(p.title)")},
                onError: {err in NSLog("Error: %@", String(describing: err))}
        )
    }
}
```

Here we see how the response is automatically decoded as a ``BlogPost`` and delivered to the ``onNext`` handler. Our ``BlogPost`` class must implement ``Decodable``.

### POST Request

In this example we POST a ``BlogPost`` object. The response is also a ``BlogPost``. As a result now our ``BlogPost`` class needs to implement both ``Encodable`` and ``Decodable``.

```swift
struct BlogPost : Decodable, Encodable {
    var id: Int
    var userId: Int
    var title: String
    var body: String
}

//...

let p = BlogPost(id: 0, userId: 1, title: "Hello World", body: "Wonderful planet")

let _ = http.post(url: "https://jsonplaceholder.typicode.com/posts", body: p)
    .execute()
    .subscribe(
        onNext: {(p:BlogPost) in print("ID: \(p.id)")},
        onError: {err in NSLog("Error: %@", String(describing: err))}
)
```

### Adding Custom Request Header

```swift
let _ = http.get(url: "https://jsonplaceholder.typicode.com/posts/1")
    .withHeader(name: "Header 1", value: "Value 1")
    .withHeader(name: "Header 2", value: "Value 2")
    .execute()
    .subscribe(
        onNext: {(p:BlogPost) in print("Title: \(p.title)")},
        onError: {err in NSLog("Error: %@", String(describing: err))}
)
```

### Working with Raw Response

In some cases you may wish to work with the low level response. For example:

- The response may not be JSON such as an image or HTML.
- You want access to response headers.

In this case subscribe for a ``WSResponse`` object.

```swift
let _ = http.get(url: "https://httpbin.org/html")
    .execute()
    .subscribe(
        onNext: {(r: WSResponse) in
            let response: HTTPURLResponse = r.response
            
            NSLog("Status code: %d", response.statusCode)
            NSLog("Content type: %@", response.allHeaderFields["Content-Type"] as! String)
            
            if let body = r.raw, let html = String(bytes: body, encoding: .utf8) {
                NSLog("HTML: %@", html)
            }
        },
        onError: { err in NSLog("Error: %@", String(describing: err))}
)
```

### Retrying GET Requests
By default GET requests are retried 3 times 5 seconds apart. Retry only happens for communication failures such as network is unavaiable. Retry does not take place for invalid status codes such as 500 and 404.

You can change the retry behavior as follows:

```swift
let _ = http.get(url: "https://BAD-HOST-jsonplaceholder.typicode.com/posts/1")
    .withRetryCount(5)
    .withRetryInterval(10)
    .execute()
    .subscribe(
        onNext: {(p:BlogPost) in print("Title: \(p.title)")},
        onError: { err in NSLog("Error: %@", String(describing: err))}
)
```

You can disable retry by setting retry count to 0.

```swift
let _ = http.get(url: "https://BAD-HOST-jsonplaceholder.typicode.com/posts/1")
    .withRetryCount(0)
    .execute()
    .subscribe(
        onNext: {(p:BlogPost) in print("Title: \(p.title)")},
        onError: { err in NSLog("Error: %@", String(describing: err))}
)
```