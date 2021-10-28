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
        
        ASRoute.shared.map(route: "/block/:id", toControllerClass: SecondVC.self)
        // 性能测试: 当注册vc增加到100000以上,内存占用上升
//        for i in 1...100000 {
//            ASRoute.shared.map(route: "/block\(i)/:id", toControllerClass: SecondVC.self)
//        }
        
        ASRoute.shared.map(route: "/block/:id") { (param: [String : Any]?) in
            print(param ?? "nil")
            let vc = SecondVC()
            vc.view.backgroundColor = .red
            self.navigationController?.pushViewController(vc, animated: true)
        }
        // 性能测试: 当注册vc增加到100000以上,内存占用不明显
//        for i in 1...100000 {
//            ASRoute.shared.map(route: "/block\(i)/:id") { (param: [String : Any]?) in
//                print(param ?? "nil")
//                let vc = SecondVC()
//                vc.view.backgroundColor = .red
//                self.navigationController?.pushViewController(vc, animated: true)
//            }
//        }
    }

    @objc func tapped(btn: UIButton) {
        switch btn {
        case btn0:
            if let vc = ASRoute.shared.matchController("/block/10?site=baidu&num=10&name=李雷") {
                navigationController?.pushViewController(vc, animated: true)
            }
        case btn1:
            ASRoute.shared.callBlock("/block/11?size=baidu&num=100&name=李雷")
            
        default:
            break
        }
    }


}

