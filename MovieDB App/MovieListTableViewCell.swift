//
//  MovieListTableViewCell.swift
//  MovieDB App
//
//  Created by Asher Ahsan on 16/08/2017.
//  Copyright © 2017 Asher Ahsan. All rights reserved.
//

import UIKit
import Kingfisher

class MovieListTableViewCell: UITableViewCell {

    @IBOutlet weak var movieReleaseDate: UILabel! //Release Date label
    @IBOutlet weak var movieOverviewTxtView: UITextView! //Overview label
    @IBOutlet weak var movieTitle: UILabel! //Title Label
    @IBOutlet weak var moviePosterImgView: UIImageView! //Movie Poster location
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell(movieInfo: Movie) {
        movieTitle.text = movieInfo.getTitle()
        movieOverviewTxtView.text = movieInfo.getOverview()
        movieReleaseDate.text = "Release Date: " + movieInfo.getReleaseDate()
        
        //Getting image from MovieDB
        let url = URL(string: "http://image.tmdb.org/t/p/w92\(movieInfo.getPosterUrl())")
        moviePosterImgView.kf.setImage(with: url, placeholder: #imageLiteral(resourceName: "samplePoster"), options: nil, progressBlock: nil, completionHandler: nil)

    }

}
