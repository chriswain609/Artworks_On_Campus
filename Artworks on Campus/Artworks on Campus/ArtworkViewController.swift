//
//  ArtworkViewController.swift
//  Artworks on Campus
//
//  Created by Christopher Wainwright on 20/12/2018.
//  Copyright © 2018 Christopher Wainwright. All rights reserved.
//

import UIKit
import CoreData

// class for table of artworks
class ArtworkViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var artworkLocation: String?
    
    var artworks = [(id: String, title: String, location: String)]()
    
    var rowID: String?
    
    // declare variables and constants for core data
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artworks")
    
    // function to return the amount of artworks at given location
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artworks.count
    }
    
    // function to display the artworks in the table
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "artworkCell")
        cell.textLabel?.text = artworks[indexPath.row].title
        cell.detailTextLabel?.text = artworks[indexPath.row].location
        return cell
    }
    
    // function to perform segue when cell tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        rowID = artworks[indexPath.row].id
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "toInfo", sender: self)
    }
    
    // function to pass id to variable in info screen
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toInfo" {
            let imageViewController = segue.destination as! ImageViewController
            imageViewController.imageID = rowID
        }
    }
    

    @IBOutlet weak var artworksTable: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        context = appDelegate.persistentContainer.viewContext

        // search for artworks at given location then reload the table so they are displayed
        let predicate = NSPredicate(format: "location == %@", artworkLocation!)
            self.request.predicate = predicate
            do {
                let results = try self.context!.fetch(self.request)
                    for result in results as! [NSManagedObject] {
                        artworks.append((id: result.value(forKey: "id") as! String, title: result.value(forKey: "title") as! String, location: result.value(forKey: "location") as! String))
                    }
            } catch {
                print("error")
            }
        
        artworksTable.reloadData()
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
