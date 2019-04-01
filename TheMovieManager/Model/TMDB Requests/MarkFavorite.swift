//
//  MarkFavorite.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation


struct MarkFavourute: Codable {
    let mediaType: String
    let mediaId: Int
    let favourite: Bool
    
    
    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case mediaId = "media_id"
        case favourite = "favorite"
    }
}
