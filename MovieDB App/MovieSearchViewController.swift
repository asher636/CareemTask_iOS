//
//  MovieSearchViewController.swift
//  MovieDB App
//
//  Created by Asher Ahsan on 16/08/2017.
//  Copyright © 2017 Asher Ahsan. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import CoreData

//Extension to auto resize textview to Movie Overview content
extension MovieSearchViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let currentOffset = tableView.contentOffset
        UIView.setAnimationsEnabled(false)
        tableView.beginUpdates()
        tableView.endUpdates()
        UIView.setAnimationsEnabled(true)
        tableView.setContentOffset(currentOffset, animated: false)
    }
}

class MovieSearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var historyTableView: UITableView!
    
    var movies = [Movie]()
    var movieHistory: [NSManagedObject] = [] //Persisting User search history
    var searchQuery: String! //Movie search text
    var resultPage = 1 //Iterator page if result returns more than 1 page
    var pageCount = 0 //Total pages in MovieDB API response
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        self.historyTableView.delegate = self
        self.historyTableView.dataSource = self
        
        historyTableView.isHidden = true
        
        searchBar.returnKeyType = .search
        
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableViewAutomaticDimension
        
        historyTableView.layer.masksToBounds = true
        historyTableView.layer.borderColor = UIColor.gray.cgColor
        historyTableView.layer.borderWidth = 1.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Search bar begins editing
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        let booleanResult = isEntityEmpty()
        if !booleanResult {
            getSearchHistory()
            switchTables(flag: 0)
        }
    }
    
    //Show/Hide history/result table
    func switchTables(flag: Int) {
        if flag == 0 {
            self.tableView.isHidden = true
            self.historyTableView.isHidden = false
            
            self.historyTableView.reloadData()
            
        } else if flag == 1 {
            self.tableView.isHidden = false
            self.historyTableView.isHidden = true
        }
    }
    
    //Calling MovieDB API to get movie results
    func getDataFromMovieDb(queryText: String, page: Int) {
        self.movies.removeAll()
        let apiUrl: String = "http://api.themoviedb.org/3/search/movie?api_key=2696829a81b1b5827d515ff121700838&query=\(queryText)&page=\(page)"
        Alamofire.request(apiUrl)
            .responseJSON { response in
                switch(response.result) {
                case .success(_):
                    if response.result.value != nil {
                        let jsonResponse = JSON(response.result.value!)
                        self.pageCount = jsonResponse["total_pages"].int!
                        
                        let resultsArray = jsonResponse["results"].arrayObject
                        
                        if (resultsArray?.isEmpty)! {
                            self.showErrorAlert(title: "Error", msg: "No record found.")
                        } else {
                            //Calling function to save data locally
                            if self.movieHistory.isEmpty {
                                self.saveQuery(name: queryText)
                            } else {
                                //Checking if name exists
                                for (index,_) in self.movieHistory.enumerated() {
                                    let movieQuery = self.movieHistory[index]
                                    let nameToCheck = movieQuery.value(forKeyPath: "name") as! String
                                    
                                    if queryText != nameToCheck {
                                        self.saveQuery(name: queryText)
                                        break //exiting for loop if data saved (to avoid duplications)
                                    }
                                }
                            }
                            
                            //Loading movie data into table
                            for result in resultsArray! {
                                let movie = Movie(data: JSON(result))
                                self.movies.append(movie)
                                self.tableView.reloadData()
                            }
                        }
                    }
                case .failure(_):
                    self.showErrorAlert(title: "Error", msg: "Invalid text entered")
                }
        }
    }
    
    //Search button clicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != nil {
            searchBar.endEditing(true)
            switchTables(flag: 1)
            
            //Calling function to call MovieDB API
            self.searchQuery = searchBar.text!
            getDataFromMovieDb(queryText: self.searchQuery, page: 1)
        }
    }
    
    
    //Number of rows for each table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            return movies.count
        } else {
            return movieHistory.count
        }
    }
    
    //Dynamic view of cells for each table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "movieCell") as! MovieListTableViewCell
            cell.movieOverviewTxtView.delegate = self
            cell.configureCell(movieInfo: movies[indexPath.row]) //configuring cell according to movie data
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "historyCell")
            let movieQuery = movieHistory[indexPath.row]
            cell?.textLabel?.text = movieQuery.value(forKeyPath: "name") as? String
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Selecting query from Search History
        if tableView == self.historyTableView {
            let cell = self.historyTableView.cellForRow(at: indexPath)
            let queryText = cell?.textLabel?.text
            getDataFromMovieDb(queryText: queryText!, page: 1)
            switchTables(flag: 1)
            searchBar.text = queryText
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        //Load page-2 movies, if page-1's movies ended
        if tableView == self.tableView && pageCount > 1 {
            if indexPath.row + 1 == movies.count {
                //Load page 2 of MovieDB
                resultPage = resultPage + 1
                getDataFromMovieDb(queryText: self.searchQuery, page: resultPage)
            }
        }
    }
    
    //Saving movie query locally - Core Data
    func saveQuery(name: String) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "History", in: managedContext)!
        let movieQuery = NSManagedObject(entity: entity, insertInto: managedContext)
        movieQuery.setValue(name, forKeyPath: "name")
        
        do {
            try managedContext.save()
            movieHistory.append(movieQuery)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    //Getting search history from CoreData
    func getSearchHistory() {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "History")
        
        do {
            movieHistory = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    //Checking if CoreData contains history
    func isEntityEmpty() -> Bool {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedContext = appDelegate?.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "History")
        
        do {
            let count = try managedContext?.count(for: fetchRequest)
            if count == 0 {
                return true
            } else {
                return false
            }
        } catch let error {
            print("error occured \(error)")
        }
        return false
    }
    
    //Alert pop-up
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}
