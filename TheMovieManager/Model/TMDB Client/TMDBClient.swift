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
        case createSessionId
        case webAuth
        case logout
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .getRequestToken:
                return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
            case .login:
                return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
            case .createSessionId:
                return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
            case .webAuth:
                    return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=mymovies:authenticate"
            case .logout:
                return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completionHandler: @escaping (ResponseType?, Error?) -> Void) {
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseData = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(responseData, nil)
                }
                
            } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                
            }
        }
        task.resume()
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        
        taskForGETRequest(url: Endpoints.getWatchlist.url, responseType: MovieResults.self) { (response, error) in
            if let response = response {
                completion(response.results, nil)
            } else {
                completion([], error)
            }
        }
    }
    
    
    class func requestToken(completionHandler: @escaping (Bool, Error?)->Void) {
        
        taskForGETRequest(url: Endpoints.getRequestToken.url, responseType: RequestTokenResponse.self) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }

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
    
    
    class func requestSessionId(completionHandler: @escaping (Bool, Error?) -> Void) {
        
        var request = URLRequest(url: Endpoints.createSessionId.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let sessionRequestBody = PostSession(requestToken: Auth.requestToken)
        request.httpBody = try! JSONEncoder().encode(sessionRequestBody)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                completionHandler(false, error)
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let sessionData = try decoder.decode(SessionResponse.self, from: data)
                Auth.sessionId = sessionData.sessionId
                completionHandler(true, nil)
            } catch {
                completionHandler(false, error)
            }
        }
        
        task.resume()
    }
    
    class func logout(completionHandler: @escaping (Error?) -> Void) {
        var request = URLRequest(url: Endpoints.logout.url)
        request.httpMethod = "DELETE"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let logoutRequest = LogoutRequest(sessionId: Auth.sessionId)
        let logoutRequestBody = try! JSONEncoder().encode(logoutRequest)
        request.httpBody = logoutRequestBody
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let _ = data else {
                completionHandler(error)
                return
            }
            Auth.requestToken = ""
            Auth.sessionId = ""
            completionHandler(nil)
        }
        task.resume()
    }
    
}
