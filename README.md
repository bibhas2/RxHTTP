## Introduction
RxHTTP is a HTTP client lirary written in Swift. It uses RxSwift for asynchronous programming.

## Main Features

- Automatic encoding and decoding of ojects to JSON. This takes advantage of the Swift generics type system to simplify coding.
- Use ``Observable`` from RxSwift project.
- A very thin layer over the native ``URLSession`` API.
- Built in retry for GET requests.
