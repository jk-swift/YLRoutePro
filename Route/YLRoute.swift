//
//  YLRoute.swift
//  YLRoute
//
//  Created by Think on 2020/6/24.
//  Copyright © 2020 Think. All rights reserved.
//

import UIKit

public protocol YLRouteEnable {
    var params: [String: String]? { get set }
}

public typealias YLRouteBlock = ([String: String]) -> ()

public enum YLRouteType {
    case none
    case controller
    case block
}

private class RouteItem {
    let route: String
    let controller: UIViewController.Type?
    let block: YLRouteBlock?
    
    init(route: String, controller: UIViewController.Type?, block: YLRouteBlock?) {
        self.route = route
        self.controller = controller
        self.block = block
    }
}

public class YLRoute {
    private var _routes: [RouteItem] = []
    private let _queue: DispatchQueue = DispatchQueue.init(label: "ylroute_array_queue", attributes: .concurrent)
    
    static public let shared = YLRoute()
    private init() { }
    
    /// map route string to controller class
    ///
    /// - Parameters:
    ///   - route: route string
    ///   - controllerClass: controller class
    public func map(route: String, toControllerClass controllerClass: UIViewController.Type) {
        let item = RouteItem.init(route: route, controller: controllerClass, block: nil)
        _queue.async(flags: .barrier) { [weak self] in
            self?._routes.append(item)
        }
    }
    
    /// match controller with route string
    ///
    /// - Parameter route: route string
    /// - Returns: controller to be routed
    public func matchController(_ route: String) -> UIViewController? {
        let (params, tController, _) = extractRoute(url: route)
        guard let controller = tController?.init() else {
            return nil
        }
        if var vc = controller as? YLRouteEnable {
            vc.params = params
        }
        return controller
    }
    
    /// map route string to block
    ///
    /// - Parameters:
    ///   - route: route string
    ///   - block: block to be routed
    public func map(route: String, toBlock block: @escaping YLRouteBlock) {
        let item = RouteItem.init(route: route, controller: nil, block: block)
        _queue.async(flags: .barrier) { [weak self] in
            self?._routes.append(item)
        }
    }
    
    /// call block with route
    ///
    /// - Parameter route: route string
    public func callBlock(route: String) {
        let (params, _, tBlock) = extractRoute(url: route, isBlock: true)
        guard let block = tBlock else { return }
        block(params)
    }
    
    /// get route type
    ///
    /// - Parameter route: route string
    /// - Returns: route type
    public func routeType(route: String) -> YLRouteType {
        let (_, controller, block) = extractRoute(url: route)
        if controller != nil {
            return .controller
        }
        if block != nil {
            return .block
        }
        return .none
    }
    
}

private extension YLRoute {
    
    func extractRoute(url: String, isBlock: Bool = false) -> ([String: String], UIViewController.Type?, YLRouteBlock?) {
        var params: [String: String] = [:]
        var controller: UIViewController.Type?
        var block: YLRouteBlock?
        
        let paramComponents = routeComponents(fromRoute: filterAppUrlScheme(url))
        
        _queue.sync { [weak self] in
            for item in _routes {
                guard let self = self, containRoute(route: item.route, url: url) == true else { continue }
                
                let routeComponents = self.routeComponents(fromRoute: item.route)
                
                guard routeComponents.count == paramComponents.count else { continue }
                
                if item.route.contains(":") {
                    for (index, value) in routeComponents.enumerated() {
                        if value.hasPrefix(":") {
                            let key = String(value.dropFirst())
                            params[key] = paramComponents[index]
                        }
                    }
                }
                
                for (key, value) in queryParams(url) {
                    params.updateValue(value, forKey: key)
                }
                
                if isBlock {
                    block = item.block
                } else {
                    controller = item.controller
                }
            }
        }
        
        return (params, controller, block)
    }
    
    func queryParams(_ query: String) -> [String: String] {
        var params: [String: String] = [:]
        if let index = query.firstIndex(of: "?") {
            let start = query.index(index, offsetBy: 1)
            let paramsString = query[start...]
            let paramsStringArr = paramsString.components(separatedBy: "&")
            for tempParam in paramsStringArr {
                let paramArr = tempParam.components(separatedBy: "=")
                if paramArr.count > 1 {
                    let key = paramArr[0], value = paramArr[1]
                    params[key] = value
                }
            }
        }
        return params
    }
    
    func routeComponents(fromRoute route: String) -> Array<String> {
        var pathComponents = [String]()
        let url: URL = URL.init(string: route.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        for pathComponent in url.pathComponents {
            if pathComponent == "/" { continue }
            if pathComponent.first == "?" { break }
            pathComponents.append(pathComponent.removingPercentEncoding!)
        }
        return pathComponents
    }
    
    func containRoute(route: String, url: String) -> Bool {
        var flag: String
        
        if route.contains(":") {
            let index = route.firstIndex(of: ":")
            flag = String(route[route.startIndex..<index!])
        } else {
            flag = route
        }
        
        return filterAppUrlScheme(url).contains(flag)
    }
    
    func filterAppUrlScheme(_ route: String) -> String {
        let urlSchemeArr = appUrlSchemes()
        for urlScheme in urlSchemeArr {
            if route.hasPrefix("\(urlScheme):") {
                let index = route.index(route.startIndex, offsetBy: (urlScheme.count + 2))
                return String(route[index..<route.endIndex])
            }
        }
        return route
    }
    
    func appUrlSchemes() -> [String] {
        var urlSchemes: [String] = []
        
        guard let infoDictionary = Bundle.main.infoDictionary, let typeArr = infoDictionary["CFBundleURLTypes"] as? Array<Any> else {
            return urlSchemes
        }
        
        for type in typeArr {
            guard let schemes = type as? Dictionary<String, Any> else {
                return urlSchemes
            }
            let schemeArr = schemes["CFBundleURLSchemes"] as? Array<String>
            if let scheme = schemeArr?.first! {
                urlSchemes.append(scheme)
            }
        }
        return urlSchemes
    }
}
