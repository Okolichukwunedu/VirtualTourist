//
//  FlickrClientUser.swift
//  VIrtualTourist
//
//  Created by Okoli-Chinedu on 28/10/2022.
//  Copyright © 2022 Okoli-Chinedu. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class FlickrClientUser {
    
    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest"
        static let flickrPhotos = "https://live.staticflickr.com/"
        static var apiKey = "24843893c3ae2c1c935bbd5364bfaf41"
        static var secret = "29dc46eb5f05f70c"
        
        case getPhotos(Double,Double,Int)
      
        var stringValue: String {
            switch self {
            case .getPhotos(let latitude, let longitude, let page):
                return Endpoints.base + "?method=flickr.photos.search" + "&api_Key=\(Endpoints.apiKey)" + "&format=json" + "&lat=\(latitude)" + "&lon=\(longitude)" + "&per_page=20" + "&page=\(Int.random(in: 1...10))" + "&nojsoncallback=1"
            }
        }
      
        var url: URL {
            return URL(string: stringValue)!
        }
    }

    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionDataTask {
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                    DispatchQueue.main.async {
                        completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
        return task
    }

    class func getPhotosFromLocation (latitude: Double, longitude: Double, page: Int, completion: @escaping (FlickrResponse?, Error?)-> Void) { taskForGETRequest(url: Endpoints.getPhotos(latitude,longitude, page).url, responseType: FlickrResponse.self) { response, error in
            if let response = response {
                DispatchQueue.main.async {
                    completion(response, nil)
                }
            } else {
                completion(nil, error)
            }
        }
    }
}
