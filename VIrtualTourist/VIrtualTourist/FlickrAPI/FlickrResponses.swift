//
//  FlickrResponses.swift
//  VIrtualTourist
//
//  Created by Okoli-Chinedu on 29/10/2022.
//  Copyright © 2022 Okoli-Chinedu. All rights reserved.
//

import Foundation

struct FlickrResponses: Codable {
    let photos: Photos
    let stat: String
}

struct Photos: Codable {
    let page, perpage : Int
    let pages, total: String
    let photo: [Photo]
}

struct Photo: Codable {
    let id, owner, secret, server: String
    let farm: Int
    let title: String
    let ispublic, isfriend, isfamily: Int
    
    enum CodingKeys: String, CodingKey {
        case id, owner, secret, title, server, farm, ispublic, isfriend, isfamily
    }
}
