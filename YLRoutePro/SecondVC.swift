//
//  SecondVC.swift
//  YLRoutePro
//
//  Created by Think on 2020/6/24.
//  Copyright © 2020 Think. All rights reserved.
//

import UIKit

class SecondVC: UIViewController, ASRouteAble {
    var params: [String : Any]?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        title = "Second"
        view.backgroundColor = .white
        
//        print(params ?? "nil")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print(params ?? "nil")
    }
    
    deinit {
        print("\(self) deinit...")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
