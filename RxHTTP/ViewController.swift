//
//  ViewController.swift
//  RxHTTP
//
//  Created by Bibhas Bhattacharya on 7/30/18.
//  Copyright © 2018 Bibhas Bhattacharya. All rights reserved.
//

import UIKit
import RxSwift

struct BlogPost : Decodable, Encodable {
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
                onNext: {(p:BlogPost) in print("Title: \(p.title)")},
                onError: { err in NSLog("Error: %@", String(describing: err))}
        )
        
        //Array test
        let _ = http.get(url: "https://jsonplaceholder.typicode.com/posts?userId=1")
            .execute()
            .subscribe(
                onNext: {(p:[BlogPost]) in print("Count: \(p.count)")},
                onError: { err in NSLog("Error: %@", String(describing: err))}
            )
        
        //POST test
        let p = BlogPost(id: 0, userId: 1, title: "Hello World", body: "Wonderful planet")
        let _ = http.post(url: "https://jsonplaceholder.typicode.com/posts", body: p)
            .execute()
            .subscribe(
                onNext: {(p:BlogPost) in print("ID: \(p.id)")},
                onError: { err in NSLog("Error: %@", String(describing: err))}
        )

        //Invalid status code test
        let _ = http.get(url: "https://jsonplaceholder.typicode.com/posts/BAD-JUJU")
            .execute()
            .subscribe(
                onNext: {(p:BlogPost) in print("Title: \(p.title)")},
                onError: { err in NSLog("Error: %@", "\(err.localizedDescription)")}
        )

        //Retry test
        let _ = http.get(url: "https://BAD-HOST-jsonplaceholder.typicode.com/posts/1")
            .execute()
            .subscribe(
                onNext: {(p:BlogPost) in print("Title: \(p.title)")},
                onError: { err in NSLog("Error: %@", String(describing: err))}
        )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

