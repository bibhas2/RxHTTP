//
//  ViewController.swift
//  RxHTTP
//
//  Created by Bibhas Bhattacharya on 7/30/18.
//  Copyright © 2018 Bibhas Bhattacharya. All rights reserved.
//

import UIKit
import RxSwift

struct BlogPost : Decodable {
    var userId:Int
    var title:String
    var body:String
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _ = http.get(url: "https://jsonplaceholder.typicode.com/posts/1").execute()
            .subscribe(
                onNext: {(p:BlogPost) in print("Title: \(p.title)")},
                onError: { err in NSLog("Error: %@", String(describing: err))}
        )
        //Array test
        let _ = http.get(url: "https://jsonplaceholder.typicode.com/posts?userId=1").execute()
            .subscribe(
                onNext: {(p:[BlogPost]) in print("Count: \(p.count)")},
                onError: { err in NSLog("Error: %@", String(describing: err))}
            )
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

