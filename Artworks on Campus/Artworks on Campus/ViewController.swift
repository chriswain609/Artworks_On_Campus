//
//  ViewController.swift
//  Artworks on Campus
//
//  Created by Christopher Wainwright on 10/12/2018.
//  Copyright © 2018 Christopher Wainwright. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData


// This class is used to create custom annotations for the artworks
class ArtworkAnnotation: NSObject, MKAnnotation {
    let id: String
    let title: String?
    let coordinate: CLLocationCoordinate2D
    let location: String
    let subtitle: String?
    var artworks = [artwork]()
    
    init(id: String, location: String, coordinate: CLLocationCoordinate2D, artworks: [artwork]) {
        self.id = id
        self.title = location
        self.location = location
        self.coordinate = coordinate
        self.subtitle = "Artworks here: " + String(artworks.count)
        self.artworks = artworks
        super.init()
    }
}

// This is the class for the initial screen of the app
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate{
    
    var artworkTitles = [String]() // an array to store the titles of artworks for search
    
    var annotations = [ArtworkAnnotation]() // an array to store map annotations
    
    var annotationLocation: String?
    
    var annotationID: String?
    
    var sections = [(heading: String, artworks: [artwork])]() // an array used to implement table headings
    
    var searchResults = [String]() // an array to store search results
    
    var searching = false
    
    // declare variables and constants to be used with core data
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artworks")
    var results: [Any]?
    
    var artworks = [artwork]()
    var sortedArtworks = [artwork]()
    var locationManager = CLLocationManager() //create an instance to manage our the user’s location.
    var first = true
    
    @IBOutlet weak var myMap: MKMapView!
    @IBOutlet weak var artworkTable: UITableView!
    @IBOutlet weak var artworkSearch: UISearchBar!
    
    var annotation: MKAnnotation?
    
    // arrays used to store and manipulate the distances of art from the user
    var locations = [(location: String, coordinate: CLLocationCoordinate2D)]()
    var distanceLocations = [(location: String, distance: Double)]()
    var sortedLocations = [(location: String, distance: Double)]()
    
    var userLocation: CLLocation?
    
    // returns the number of sections, 1 if searching
    func numberOfSections(in tableView: UITableView) -> Int {
        if searching {
            return 1
        } else {
            return sections.count
        }
    }
    
    // returns the section headers, results if searching
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searching {
            return "Results"
        } else {
            return sortedLocations[section].location
        }
    }
    
    //returns the number of rows in a section, the number of restults if searching
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searching {
            return searchResults.count
        } else {
            return sections[section].artworks.count
        }
    }
    
    // returns reusable cell containing the title of the art and the artist
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")
        
        if searching {
            cell.textLabel?.text = searchResults[indexPath.row]
        } else {
            cell.textLabel?.text = sections[indexPath.section].artworks[indexPath.row].title
            cell.detailTextLabel?.text = sections[indexPath.section].artworks[indexPath.row].artist
        }
        return cell
    }
    
    // function to handle cell being tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // get the title of the tapped cell and use this to search core data for that piece of art
        let selectedCell = artworkTable.cellForRow(at: indexPath)
        let title = selectedCell?.textLabel?.text
        let predicate = NSPredicate(format: "title == %@", title!)
        var long: String?
        var lat: String?
        self.request.predicate = predicate
        do {
            let results = try self.context!.fetch(self.request)
            // with the result use the coordinates to go to the position of this artwork on the map
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    long = (result.value(forKey: "long") as! String)
                    lat = (result.value(forKey: "lat") as! String)
                }
                let latDelta: CLLocationDegrees = 0.001
                let lonDelta: CLLocationDegrees = 0.001
                let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
                let location = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat!)!, longitude: CLLocationDegrees(long!)!)
                let region = MKCoordinateRegion(center: location, span: span)
                self.myMap.setRegion(region, animated: true)
            }
        } catch {
            print("error")
        }
    }
    
    // clear the text from the search bar when it is tapped
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        artworkSearch.text = ""
        searching = false
        artworkTable.reloadData()
    }
    
    // close the keyboard when the search button is clicked
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.artworkSearch.resignFirstResponder()
    }
    
    // close the keyboard, empty the search bar and reload the table when cancel clicked
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        artworkSearch.text = ""
        searching = false
        self.artworkSearch.resignFirstResponder()
        artworkTable.reloadData()
    }
    
    // method to handle typing in the search bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // if no text then end searching
        if artworkSearch.text == "" {
            searching = false
        } else {
            // if text changed to not empty filter the titles of the artworks to see if they have a prefix matching the searched term
            searching = true
            let searchText = artworkSearch.text
            searchResults = artworkTitles.filter({$0.hasPrefix(searchText!)})
        }
        artworkTable.reloadData()
    }
    
    // function to create the custom annotation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "Artwork"
        
        // use artwork annotation class and search for an image related to the building the annotation is of
        // use the first result as the image for the annotation
        if annotation is ArtworkAnnotation {
            if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                annotationView.annotation = annotation
                return annotationView
            } else {
                let artworkAnotation = annotation as! ArtworkAnnotation
                let predicate = NSPredicate(format: "location == %@", artworkAnotation.location)
                self.request.predicate = predicate
                var annotationImage: UIImage?
                do {
                    let results = try self.context!.fetch(self.request)
                    
                    if results.count > 0 {
                        let imageData = (results[0] as AnyObject).value(forKey: "image") as! NSData
                        annotationImage = (UIImage(data: imageData as Data)!)
                    }
                } catch {
                    print("error")
                }
                // make the annotation a marker
                // (could be a pin with MKPinAnnotationView, I thought marker looked better as you could see the location name below)
                let annotationView = MKMarkerAnnotationView(annotation:annotation, reuseIdentifier: identifier)
                annotationView.isEnabled = true
                annotationView.canShowCallout = true // allow marker to show more info when tapped
                
                // add i button on the right of the callout
                let button = UIButton(type: .detailDisclosure)
                annotationView.rightCalloutAccessoryView = button
                
                // add image on the left of the callout, a square of length and width, the height of callout
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: annotationView.frame.height, height: annotationView.frame.height))
                if annotationImage != nil {
                    imageView.image = annotationImage!
                    imageView.contentMode = .scaleAspectFit
                    annotationView.leftCalloutAccessoryView = imageView
                }
                return annotationView
            }
        }
        
        return nil
    }
    
    // function for when annotation button tapped
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        // search core data for the location. If there is a single result then go to the info screen, if not go to the table.
        guard let annotation = view.annotation as? ArtworkAnnotation else {return}
        annotationLocation = annotation.location
        let predicate = NSPredicate(format: "location == %@", annotationLocation!)
        self.request.predicate = predicate
        do {
            results = try self.context!.fetch(self.request)
            if results!.count > 1 {
                performSegue(withIdentifier: "annotationPressed", sender: self)
            } else {
                for result in results as! [NSManagedObject] {
                    annotationID = (result.value(forKey: "id") as! String)
                    performSegue(withIdentifier: "mainToInfo", sender: self)
                }
            }
        } catch {
            print("error")
        }
    }

    // function to pass variables before segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // if multiple artworks then pass location to table
        if segue.identifier == "annotationPressed" {
            let artworkViewController = segue.destination as! ArtworkViewController

            artworkViewController.artworkLocation = annotationLocation

            // if a single artwork pass id to info screen
        } else if segue.identifier == "mainToInfo" {
            let imageViewController = segue.destination as! ImageViewController
            imageViewController.imageID = annotationID
        }

    }
    
    // function for downloading image, takes the url and an artwork as parameter
    // also saves artwork to core data
    func getImage(imageURL: String, artwork: artwork) {
        // create background task with the url and download the image at the url.
        let url = URL(string: imageURL)
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: url!) { (data, response, error) in
            if error != nil {
                print(error!)
            } else {
                if (response as? HTTPURLResponse) != nil {
                    if let imageData = data {
                        let image = NSData(data: imageData)
                        DispatchQueue.main.async {
                            // wait for image to download then save image and artwork info to core data
                            let newItem = NSEntityDescription.insertNewObject(forEntityName: "Artworks", into: self.context!) as! Artworks
                            newItem.setValue(artwork.id, forKey: "id")
                            newItem.setValue(image, forKey: "image")
                            newItem.setValue(artwork.title, forKey: "title")
                            newItem.setValue(artwork.artist, forKey: "artist")
                            newItem.setValue(artwork.yearOfWork, forKey: "yearOfWork")
                            newItem.setValue(artwork.Information, forKey: "information")
                            newItem.setValue(artwork.lat, forKey: "lat")
                            newItem.setValue(artwork.long, forKey: "long")
                            newItem.setValue(artwork.location, forKey: "location")
                            newItem.setValue(artwork.locationNotes, forKey: "locationNotes")
                            newItem.setValue(artwork.fileName, forKey: "fileName")
                            newItem.setValue(artwork.lastModified, forKey: "lastModified")
                            newItem.setValue(artwork.enabled, forKey: "enabled")
                            do {
                                try self.context?.save()
                                print("saved")
                            } catch {
                                print("error")
                            }
                        }
                    }
                }
            }
            
        }
        task.resume()
    }
    
    // function to get the users location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // if it is the first time the location has updated do this, otherwise dont
        if first {
            let locationOfUser = locations[0] // this didnt work
            // get latitude and longitude of user
            let latitude = locationOfUser.coordinate.latitude
            let longitude = locationOfUser.coordinate.longitude
            userLocation = CLLocation(latitude: latitude, longitude: longitude)
            // set visible size
            let latDelta: CLLocationDegrees = 0.008
            let lonDelta: CLLocationDegrees = 0.008
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            // set centre and visible area
            let region = MKCoordinateRegion(center: location, span: span)
            self.myMap.setRegion(region, animated: true)
            //create annotation for user location
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            annotation.title = "You are here"
            self.myMap.addAnnotation(annotation)
            first = false
        }
    }
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        guard let annotation = annotation as? ArtworkAnnotation else { return nil }
//
//        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "marker")
//
//        if annotationView == nil {
//            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "marker")
//            annotationView!.canShowCallout = true
//            annotationView!.image = UIImage(named: "pin")
//            let image = UIImage(named: "pin")
//            image?.size = CGSize(width: 50, height: 50)
//        } else {
//            annotationView!.annotation = annotation
//        }
//
//        return annotationView
//    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        context = appDelegate.persistentContainer.viewContext
        
        // ask user to allow location info to be used
        locationManager.delegate = self as CLLocationManagerDelegate //we want messages about location
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization() //ask the user for permission to get their location
        locationManager.startUpdatingLocation() //and start receiving those messages (if we’re allowed to)
        
        let urlString = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artworksOnCampus/data.php?class=artworks2&lastUpdate=2017-11-01"
        guard let url = URL(string: urlString) else {return}
        
        // create background task to get artworks from json file at url
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                print(error!)
            } else {
                if let urlContent = data {
                    do {
                        // use json decoder to get data
                        let data = Data(urlContent)
                        let decoder = JSONDecoder()
                        let artworkList = try decoder.decode(artworksOnCampus.self, from: data)
                        self.artworks = artworkList.artworks2!
                        // search to check if artworks have already been saved
                        // if so, dont download
                        // if they havent been saved then call the method to download images and save
                        for artwork in self.artworks {
                            let id = artwork.id
                            let predicate = NSPredicate(format: "id == %@", id)
                            self.request.predicate = predicate
                            do {
                                let results = try self.context!.fetch(self.request)
                                
                                if results.count == 0 {
                                    let imageString = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artwork_images/" + artwork.fileName.replacingOccurrences(of: " ", with: "%20", options: .literal, range: nil)
                                    self.getImage(imageURL: imageString, artwork: artwork)
                                }
                            } catch {
                                print("error")
                            }
                        }
                        
                        // sort artworks in alphabetic order according to location
                        self.sortedArtworks = self.artworks.sorted {
                                return $0.location > $1.location
                        }
                        
                        // wait for background task to finish
                        DispatchQueue.main.async {
                            var artworksAtLocation = [artwork]()
                            var previousLocation = "abcde"
                            var id = 0
                            // create array of unique locations and artwork annotations
                            for i in 0 ..< self.sortedArtworks.count {
                                if self.sortedArtworks[i].location != previousLocation {
                                    if i != 0 {
                                        id += 1
                                        let stringID = String(id)
                                        guard let latitude = Double(self.sortedArtworks[i-1].lat) else { return }
                                        guard let longitude = Double(self.sortedArtworks[i-1].long) else { return }
                                        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                        let artworkAnnotation = ArtworkAnnotation(id: stringID, location: self.sortedArtworks[i-1].location, coordinate: coordinate, artworks: artworksAtLocation)
                                        self.locations.append((location: self.sortedArtworks[i-1].location, coordinate: coordinate))
                                        self.annotations.append(artworkAnnotation)
                                    }
                                    artworksAtLocation = []
                                    
                                    artworksAtLocation.append(self.sortedArtworks[i])
                                    previousLocation = self.sortedArtworks[i].location
                                } else {
                                    artworksAtLocation.append(self.sortedArtworks[i])
                                }
                            }
                            id += 1
                            let stringID = String(id)
                            guard let latitude = Double(self.sortedArtworks[self.sortedArtworks.count-1].lat) else { return }
                            guard let longitude = Double(self.sortedArtworks[self.sortedArtworks.count-1].long) else { return }
                            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                            let artworkAnnotation = ArtworkAnnotation(id: stringID, location: self.sortedArtworks[self.sortedArtworks.count-1].location, coordinate: coordinate, artworks: artworksAtLocation)
                            self.locations.append((location: self.sortedArtworks[self.sortedArtworks.count-1].location, coordinate: coordinate))
                            self.annotations.append(artworkAnnotation)
                            self.myMap.addAnnotations(self.annotations)
                            
                            // calculate the distances of the locations from the user
                            for location in self.locations {
                                let coordinates = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                                
                                let distance = coordinates.distance(from: self.userLocation!)
                                self.distanceLocations.append((location: location.location, distance: distance))
                            }
                            
                            // sort the distances of the locations from the user
                            self.sortedLocations = self.distanceLocations.sorted {
                                return $0.distance < $1.distance
                            }
                            
                            // create a dictionary containing locations and an array of corresponding artworks
                            // this is in order of distance from the user as they have already been sorted
                            for location in self.sortedLocations {
                                var temp = [artwork]()
                                for artwork in self.artworks {
                                    if artwork.location == location.location {
                                        temp.append(artwork)
                                    }
                                }
                                self.sections.append((heading: location.location, artworks: temp))
                            }
                            
                            self.artworkTable.reloadData()
                            
                            // add all the titles of artworks to another array, this will be used for searching
                            for artwork in self.artworks {
                                self.artworkTitles.append(artwork.title)
                            }
                            
                        }
                        
                    } catch let jsonErr {
                        print("error", jsonErr)
                    }
                }
            }
        }
        task.resume()
        
        
    }


}

