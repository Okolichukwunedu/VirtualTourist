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
    let page, pages, prepage, total: Int
    let photo: [Photo]
}

struct Photo: Codable {
    let id, owner, secret, server: String
    let farm: Int
    let title: String
    let ispublic, isfriend, isfamily: Int
    let urlM: String
    let heightM, widthM: Int
    
    enum CodingKeys: String, CodingKey {
        case id, owner, secret, title, server, farm, ispublic, isfriend, isfamily
        case urlM = "url_m"
        case heightM = "height_m"
        case widthM = "width_m"
    }
}
