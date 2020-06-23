//
//  ViewController.swift
//  YLRoutePro
//
//  Created by Think on 2020/6/24.
//  Copyright © 2020 Think. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    lazy var btn0: UIButton = {
        let btn0 = UIButton.init(type: .roundedRect)
        btn0.frame = CGRect.init(x: 50, y: 100, width: 150, height: 44)
        btn0.setTitle("process to url", for: .normal)
        btn0.backgroundColor = .blue
        btn0.addTarget(self, action: #selector(tapped(btn:)), for: .touchUpInside)
        
        return btn0
    }()
    
    lazy var btn1: UIButton = {
        let btn1 = UIButton.init(type: .roundedRect)
        btn1.frame = CGRect.init(x: 50, y: 150, width: 150, height: 44)
        btn1.setTitle("call block", for: .normal)
        btn1.backgroundColor = .blue
        btn1.addTarget(self, action: #selector(tapped(btn:)), for: .touchUpInside)
        
        return btn1
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        title = "Root"
        view.backgroundColor = .white
        view.addSubview(btn0)
        view.addSubview(btn1)
        
        YLRoute.shared.map(route: "/second/:page", toControllerClass: SecondVC.self)
        YLRoute.shared.map(route: "/block/:id") { (param: [String : String]) in
            print(param)
        }
    }

    @objc func tapped(btn: UIButton) {
        if btn == btn0, let vc = YLRoute.shared.matchController("/second/10?site=baidu&num=10") {
            navigationController?.pushViewController(vc, animated: true)
        }
        
        if btn == btn1 {
            YLRoute.shared.callBlock(route: "/block/11?size=baidu&num=100")
        }
    }


}

