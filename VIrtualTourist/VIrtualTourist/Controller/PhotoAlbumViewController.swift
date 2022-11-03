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
    var annotation: MKAnnotation!
    var dataController: DataController!
    var pinLocation: PinLocation!
    var photoArray: [PhotoAlbum] = []
    var images: [UIImage] = []
    
    //MARK: Life Cylcles
    override func viewDidLoad () {
        super.viewDidLoad()
        
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        let _ = (view.frame.size.height - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        fetchResultFromCoreData()
        getPhotos()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getHeaderMap(latitude: pinLocation.latitude, longitude: pinLocation.longitude)
    }
 
    @IBAction func newCollecionButtonClicked(_ sender: Any) {
        let fetchRequest: NSFetchRequest<PhotoAlbum> = PhotoAlbum.fetchRequest()
        if let photos = fetchRequest {
          for photo in photos {
              self.dataController.viewContext.delete(photo)
              try? self.dataController.viewContext.save()
            }
        }
    }
    
    func fetchResultFromCoreData () {
        let fetchRequest: NSFetchRequest<PhotoAlbum> = PhotoAlbum.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "pin" , ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            photoArray = result
            collectionPhotoView.reloadData()
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
    
    func getPhotos () {
        FlickrClientUser.getPhotosFromLocation(latitude: pinLocation?.latitude, longitude: pinLocation?.longitude) { (response, error) in
            DispatchQueue.main.async {
            }
        }
    }
}

extension PhotoAlbumViewController {
    func showErrorAlert(title: String, message: String) {
        let alertViewController = UIAlertController (title: title,  message: message, preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: "Error", style: .default, handler: nil))
        self.present(alertViewController, animated: true, completion: nil)
    }
        
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoArray?.count ?? 1
    }
       
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCell
        cell.imageView?.image = UIImage(data: photoArray[indexPath.row].data!)
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
