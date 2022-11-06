//
//  PhotoAlbumViewController.swift
//  VIrtualTourist
//
//  Created by Okoli-Chinedu on 28/10/2022.
//  Copyright © 2022 Okoli-Chinedu. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    //MARK: Outlet
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionPhotoView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    //MARK: Properties and Variables
    var selectedPin: CLLocationCoordinate2D?
    var annotation: MKAnnotation!
    var dataController: DataController!
    var pinLocations: PinLocation!
    var photoArray: PhotoAlbum!
    var page: Int = 0
    var fetchedResultsController: NSFetchedResultsController<PhotoAlbum>!
    
    //MARK: Life Cylcles
    override func viewDidLoad () {
        super.viewDidLoad()
        
        mapView.delegate = self
        collectionPhotoView.delegate = self
        flowLayoutSet()
        fetchResultFromCoreData()
        getPhotos()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getHeaderMap(latitude: pinLocations.latitude, longitude: pinLocations.longitude)
    }
    
    fileprivate func flowLayoutSet() {
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        let _ = (view.frame.size.height - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        collectionPhotoView.collectionViewLayout = UICollectionViewFlowLayout()
    }
 
    @IBAction func newCollecionButtonClicked(_ sender: Any) {
        for images in fetchedResultsController.fetchedObjects! {
            self.dataController.viewContext.delete(images)
        }
        try? self.dataController.viewContext.save()
        getPhotos()
    }
    
    func fetchResultFromCoreData () {
        let fetchRequest: NSFetchRequest<PhotoAlbum> = PhotoAlbum.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", self.pinLocations)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "pin" , ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func getHeaderMap(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = latitude
        annotation.coordinate.longitude = longitude
        let span = MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        mapView.addAnnotation(annotation)
        self.mapView.setRegion(region, animated: false)
        self.mapView.setCenter(annotation.coordinate, animated: false)
        self.mapView.regionThatFits(region)
    }
    
    func downloadImage( imagePath: String, completionHandler: @escaping (_ imageDate: Data?, _ errorString: String?) -> Void) {
        let session = URLSession.shared
        let imgURL = NSURL(string: imagePath)
        let request: NSURLRequest = NSURLRequest(url: imgURL! as URL)
        
        let task = session.dataTask(with: request as URLRequest) {data, response, downloadError in
            if downloadError != nil {
                completionHandler(nil, "Could not donwload image \(imagePath)")
            }else {
                completionHandler(data, nil)
            }
        }
        task.resume()
    }
    
    func getPhotos () {
        FlickrClientUser.getPhotosFromLocation(latitude: pinLocations!.latitude, longitude: pinLocations?.longitude ?? 0.0, page: page, completion: { (response, error) in
            if let response = response {
                let downloadedImageUrls = response.photos.photo
                for photo in downloadedImageUrls {
                    let newPhoto = PhotoAlbum(context: self.dataController.viewContext)
                    newPhoto.coreURL = photo.urlM
                    newPhoto.pin = self.pinLocations
                    try? self.dataController.viewContext.save()
                }
                self.collectionPhotoView.reloadData()
            } else {
                self.showErrorAlert(title: "Error!", message: "No Photos Found For This Location.")
            }
        })
    }
}

extension PhotoAlbumViewController {
    func showErrorAlert(title: String, message: String) {
        let alertViewController = UIAlertController (title: title,  message: message, preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: "Error", style: .default, handler: nil))
        self.present(alertViewController, animated: true, completion: nil)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
       
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCell
        let cellImage = fetchedResultsController.fetchedObjects![indexPath.row]
        if cellImage.corePhoto == nil {
            if let url = URL(string: cellImage.coreURL ?? "") {
                downloadImage(imagePath: url.absoluteString) { (data, error) in
                    DispatchQueue.main.async {
                        cell.imageView.image = UIImage(data: data!)
                    }
                cellImage.corePhoto = data
                try! self.dataController.viewContext.save()
                }
            }
        }
        //let url = URL(data: photos[indexPath.row].corePhoto!)!
        //cell.imageView?.image(with: url)
        return cell
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
            
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.image = UIImage(named: "icon_pin")
            pinView!.canShowCallout = true
            pinView!.isDraggable = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}
