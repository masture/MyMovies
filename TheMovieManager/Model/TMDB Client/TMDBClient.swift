//
//  TMDBClient.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation

class TMDBClient {
    
    static let apiKey = "183891cfcf042a3332cfab122f8e138b"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        
        case getWatchlist
        case getRequestToken
        case login
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken:
                return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login:
                return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.getWatchlist.url) { data, response, error in
            guard let data = data else {
                completion([], error)
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(MovieResults.self, from: data)
                completion(responseObject.results, nil)
            } catch {
                completion([], error)
            }
        }
        task.resume()
    }
    
    
    class func requestToken(completionHandler: @escaping (Bool, Error?)->Void) {
        
        let task = URLSession.shared.dataTask(with: Endpoints.getRequestToken.url) { (data, response, error) in
            
            guard let data = data else {
                completionHandler(false, error)
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let requestTokenResponse = try decoder.decode(RequestTokenResponse.self, from: data)
                Auth.requestToken = requestTokenResponse.requestToken
                completionHandler(true, nil)
            } catch {
                completionHandler(false, error)
            }
        }
        
        task.resume()

    }
    
    
    class func requestLogin(for user: LoginRequest,completionHandler: @escaping (Bool, Error?)->Void) {
        
        var request = URLRequest(url: Endpoints.login.url)
        request.httpMethod = "POST"
        
        let encoder = JSONEncoder()
        
        do {
            let jsonLoginRequestBody = try encoder.encode(user)
            request.httpBody = jsonLoginRequestBody
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                guard let data = data else {
                    completionHandler(false, error)
                    return
                }
                
                let decoder = JSONDecoder()
                
                do {
                    let responseObject = try decoder.decode(RequestTokenResponse.self, from: data)
                    Auth.requestToken = responseObject.requestToken
                    completionHandler(true, nil)
                } catch {
                    completionHandler(false, nil)
                }

            }
            
            task.resume()
            
        }catch {
            completionHandler(false, error)
        }
    }
    
}
