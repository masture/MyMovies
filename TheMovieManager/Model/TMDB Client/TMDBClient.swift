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
        case getFavourites
        case search(String)
        case markWatchList
        case markFavourite
        case posterImageURL(String)
        
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
            case .getFavourites:
                return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
            case .search(let query):
                return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            case .markWatchList:
                return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=" + Auth.sessionId
            case .markFavourite:
                return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=" + Auth.sessionId
            case .posterImageURL(let posterPath):
                return "https://image.tmdb.org/t/p/w500/" + posterPath
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    
    class func downloadPosterImage(posterPath: String, completionHandler: @escaping (Data?, Error?) -> Void) {
        
        let url = Endpoints.posterImageURL(posterPath).url
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(data, nil)
            }
        }
        
        task.resume()
        
    }
    
    
    class func markFavourite(movieID: Int, markFavouture: Bool, completionHandler: @escaping (Bool, Error?) -> Void) {
        let markFavouriteList = MarkFavourute(mediaType: "movie", mediaId: movieID, favourite: markFavouture)
        
        taskForPOSTRequest(url: Endpoints.markFavourite.url, responseType: TMDBResponse.self, body: markFavouriteList) { (response, error) in
            if let response = response {
                completionHandler([1, 12, 13].contains(response.statusCode), nil)
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    class func markWatchlist(movieId: Int, watchlist: Bool, compltionHandler: @escaping (Bool, Error?) -> Void) {
        let markWatchlist = MarkWatchList(mediaType: "movie", mediaId: movieId, watchlist: watchlist)
        
        taskForPOSTRequest(url: Endpoints.markWatchList.url, responseType: TMDBResponse.self, body: markWatchlist) { (response, error) in
            if let response = response {
                compltionHandler([1, 12, 13].contains(response.statusCode), nil)
            } else {
                compltionHandler(false, error)
            }
        }
        
    }
    
    
    class func seach (movieName: String, completionHandler: @escaping ([Movie], Error?) -> Void) {
        
        taskForGETRequest(url: Endpoints.search(movieName).url, responseType: MovieResults.self) { (response, error) in
            if let response = response {
                completionHandler(response.results, nil)
            } else {
                completionHandler([], error)
            }
        }
        
    }
    
    class func getFavourites(completionHandler: @escaping ([Movie], Error?) -> Void) {
        
        taskForGETRequest(url: Endpoints.getFavourites.url, responseType: MovieResults.self) { (response, error) in
            if let response = response {
                completionHandler(response.results, nil)
            } else {
                completionHandler([], error)
            }
        }
        
    }

    class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, body: RequestType, completion: @escaping (ResponseType?, Error?) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONEncoder().encode(body)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(response, nil)
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
        
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
        
        taskForPOSTRequest(url: Endpoints.login.url, responseType: RequestTokenResponse.self, body: user) { (response, error) in
            if let response = response {
                Auth.requestToken = response.requestToken
                completionHandler(true, nil)
            } else {
                completionHandler(false, error)
            }
        }
    }
    
    
    class func requestSessionId(completionHandler: @escaping (Bool, Error?) -> Void) {
        
        let sessionRequestBody = PostSession(requestToken: Auth.requestToken)
        
        taskForPOSTRequest(url: Endpoints.createSessionId.url, responseType: SessionResponse.self, body: sessionRequestBody) { (response, error) in
            
            if let response = response {
                Auth.sessionId = response.sessionId
                completionHandler(true, nil)
            } else {
                completionHandler(false, nil)
            }
        }
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
