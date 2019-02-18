//
//  ImageViewController.swift
//  Artworks on Campus
//
//  Created by Christopher Wainwright on 14/12/2018.
//  Copyright © 2018 Christopher Wainwright. All rights reserved.
//

import UIKit
import CoreData

class ImageViewController: UIViewController {
    
    // declare variables and constants for core data
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artworks")
    var results: [Any]?
    
    var imageID: String?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var infoLabel: UITextView!
    
    @IBOutlet weak var displayImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        context = appDelegate.persistentContainer.viewContext
        
        // search for the artwork with given id in core data
        let predicate = NSPredicate(format: "id == %@", imageID!)
        self.request.predicate = predicate
        var image: UIImage?
        do {
            let results = try self.context!.fetch(self.request)
            
            if results.count > 0 {
                // if artwork found, display info about it
                titleLabel.text? = (results[0] as! NSManagedObject).value(forKey: "title") as! String
                yearLabel.text? = (results[0] as! NSManagedObject).value(forKey: "yearOfWork") as! String
                artistLabel.text? = (results[0] as! NSManagedObject).value(forKey: "artist") as! String
                infoLabel.text? = (results[0] as! NSManagedObject).value(forKey: "information") as! String
                // start scrollable text view at the top
                infoLabel.setContentOffset(.zero, animated: true)
                // display image and scale to fit image view without stretching
                let imageData = (results[0] as AnyObject).value(forKey: "image") as! NSData
                image = (UIImage(data: imageData as Data)!)
                if image != nil {
                    displayImage.image = image!
                    displayImage.contentMode = .scaleAspectFit
                }
            }
        } catch {
            print("error")
        }
        // Do any additional setup after loading the view.
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
