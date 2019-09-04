//
//  PhotoModel.swift
//  AssignementT2
//
//  Created by apple on 02/09/19.
//  Copyright © 2019 Swiftter. All rights reserved.
//

import Foundation

class PhotoModel : Equatable {
    let photoID : String
    let farm : Int
    let server : String
    let secret : String
    
    init (photoID:String,farm:Int, server:String, secret:String) {
        self.photoID = photoID
        self.farm = farm
        self.server = server
        self.secret = secret
    }
    
    func imageURL(_ size:String = "m") -> URL? {
        if let url =  URL(string: "https://farm\(farm).staticflickr.com/\(server)/\(photoID)_\(secret)_\(size).jpg") {
            return url
        }
        return nil
    }
    
}

func == (lhs: PhotoModel, rhs: PhotoModel) -> Bool {
    return lhs.photoID == rhs.photoID
}
