//
//  ASRoute.swift
//  YLRoutePro
//
//  Created by Abel Swift on 2021/10/28.
//  Copyright © 2021 Think. All rights reserved.
//

import UIKit

public typealias ASRouteBlock = ([String: Any]?) -> ()
public typealias ASRouteParam = [String: Any]

public protocol ASRouteAble {
    
    var params: ASRouteParam? { get set }
}

public enum ASRouteTarget {
    
    case vc(route: String, vcType: UIViewController.Type)
    case block(route: String, block: ASRouteBlock)
}

public class ASRoute {
    
    private var _routes: [ASRouteTarget] = []
    private let _queue: DispatchQueue = DispatchQueue(label: "ylroute_array_queue", attributes: .concurrent)
    
    static public let shared = ASRoute()
    private init() { }
    
    /// map route string to controller class
    ///
    /// - Parameters:
    ///   - route: route string
    ///   - controllerClass: controller class
    public func map(route: String, toControllerClass controllerClass: UIViewController.Type) {
        let target = ASRouteTarget.vc(route: route, vcType: controllerClass)
        _queue.async(flags: .barrier) { [weak self] in
            self?._routes.append(target)
        }
    }
    
    /// match controller with route string
    ///
    /// - Parameter url: url string
    /// - Returns: controller to be routed
    public func matchController(_ url: String) -> UIViewController? {
        let paramComponents = routeComponents(fromRoute: filterAppUrlScheme(url))
        var cla: UIViewController.Type?
        var params: [String: Any]?
        
        _queue.sync { [weak self] in
            for item in _routes {
                guard let self = self,
                      case .vc(let route, let vcType) = item,
                      let param = self.extractParams(in: url, for: route, paramComponents: paramComponents)
                else {
                    continue
                }
                cla = vcType
                params = param
                break
            }
        }
        
        guard let targetType = cla else { return nil }
        
        let controller = targetType.init()
        if var vc = controller as? ASRouteAble {
            vc.params = params
        }
        return controller
    }
    
    /// map route string to block
    ///
    /// - Parameters:
    ///   - route: route string
    ///   - block: block to be routed
    public func map(route: String, toBlock block: @escaping ASRouteBlock) {
        let target = ASRouteTarget.block(route: route, block: block)
        _queue.async(flags: .barrier) { [weak self] in
            self?._routes.append(target)
        }
    }
    
    /// call block with route
    ///
    /// - Parameter url: url string
    public func callBlock(_ url: String) {
        let paramComponents = routeComponents(fromRoute: filterAppUrlScheme(url))
        var params: [String: Any]?
        var targetBlock: ASRouteBlock?
        
        _queue.sync { [weak self] in
            for item in _routes {
                guard let self = self,
                      case .block(let route, let block) = item,
                      let param = self.extractParams(in: url, for: route, paramComponents: paramComponents)
                else {
                    continue
                }
                params = param
                targetBlock = block
                break
            }
        }
        targetBlock?(params)
    }
    
}

private extension ASRoute {
    
    func extractParams(in url: String, for route: String, paramComponents: [String]) -> ASRouteParam? {
        guard containRoute(route: route, url: url) else { return nil }
        
        let routeComponents = self.routeComponents(fromRoute: route)
        guard routeComponents.count == paramComponents.count else { return nil }
        
        var params: [String: Any] = [:]
        if route.contains(":") {
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
        
        return params
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
    
    func routeComponents(fromRoute route: String) -> [String] {
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
