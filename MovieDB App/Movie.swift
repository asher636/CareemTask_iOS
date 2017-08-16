//
//  Movie.swift
//  MovieDB App
//
//  Created by Asher Ahsan on 16/08/2017.
//  Copyright © 2017 Asher Ahsan. All rights reserved.
//

import Foundation
import SwiftyJSON

class Movie {
    var title: String
    var releaseDate: String
    var overview: String
    var posterUrl: String
    
    //Getters
    func getTitle() -> String {
        return title
    }
    
    func getReleaseDate() -> String {
        return releaseDate
    }
    
    func getOverview() -> String {
        return overview
    }
    
    func getPosterUrl() -> String {
        return posterUrl
    }
    
    //Setters
    init(data: JSON) {
        if !(data["original_title"].null != nil) {
            self.title = data["original_title"].string!
        } else {
            self.title = "Not Available"
        }
        
        if !(data["release_date"].null != nil) {
            self.releaseDate = data["release_date"].string!
        } else {
            self.releaseDate = "Not Aavailable"
        }
        
        if !(data["overview"].null != nil) {
            self.overview = data["overview"].string!
        } else {
            self.overview = "Not Aavailable"
        }
        
        if !(data["poster_path"].null != nil) {
            self.posterUrl = data["poster_path"].string!
        } else {
            self.posterUrl = "Not Aavailable"
        }
    }
}
