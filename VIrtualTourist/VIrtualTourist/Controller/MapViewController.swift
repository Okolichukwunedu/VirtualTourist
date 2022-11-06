//
//  MapViewController.swift
//  VIrtualTourist
//
//  Created by Okoli-Chinedu on 28/10/2022.
//  Copyright © 2022 Okoli-Chinedu. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    
    //MARK: Outlet
    @IBOutlet weak var mapView: MKMapView!
    
    //MARK: Properties and Variables
    var dataController: DataController!
    var pinLocations: PinLocation!
    var annotation: MKAnnotation!
    var fetchedResultsController: NSFetchedResultsController<PinLocation>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        fetchResultFromCoreData()
        addLongPressGesture()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    func fetchResultFromCoreData () {
        let fetchRequest: NSFetchRequest<PinLocation> = PinLocation.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude" , ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
               fetchedResultsController.delegate = self
               do {
                   try fetchedResultsController.performFetch()
               } catch {
                   fatalError("The fetch could not be performed: \(error.localizedDescription)")
               }
        addAnnotations()
    }
    
    @objc func handleTap(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != .began {
            return
        }
        let touchPoint = gestureRecognizer.location(in: self.mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.title = "Latitude: \(touchCoordinate.latitude)"
        annotation.subtitle = "Longitude: \(touchCoordinate.longitude)"
        annotation.coordinate = touchCoordinate
        let pinLocation = PinLocation(context: dataController.viewContext)
        pinLocation.latitude = touchCoordinate.latitude
        pinLocation.longitude = touchCoordinate.longitude
        try? dataController.viewContext.save()
        DispatchQueue.main.async {
            self.mapView.addAnnotation(annotation)
        }
    }
    
    func addAnnotations(){
        mapView.removeAnnotations(mapView.annotations)
        var annotations = [MKPointAnnotation]()
        let pins = fetchedResultsController.fetchedObjects!
        for pin in pins {
            let latitude = CLLocationDegrees(pin.latitude)
            let longitude = CLLocationDegrees(pin.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        self.mapView.addAnnotations(annotations)
    }
    
    func addLongPressGesture(){
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleTap))
        longPressGesture.delegate = self
        //MARK: Long Press (2 seconds Duration)
        longPressGesture.minimumPressDuration = 2
        self.mapView.addGestureRecognizer(longPressGesture)
        self.mapView.isScrollEnabled = true
        self.mapView.isZoomEnabled = true
        self.mapView.showsCompass = true
        self.mapView.showsTraffic = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if (segue.identifier == "showFlickrPhoto") {
            // Instantiate the PhotoAlbumViewController
            let vc = segue.destination as? PhotoAlbumViewController
            vc?.pinLocations = self.pinLocations
            vc?.dataController = self.dataController
        }
    }
}

extension MapViewController {
    
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
            pinView!.canShowCallout = false
            pinView!.isDraggable = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let annotation = view.annotation
        //get coordinates
        let latitude = annotation?.coordinate.latitude
        let longitude = annotation?.coordinate.longitude
        //mapView.deselectAnnotation(view.annotation, animated: true)
        //get pin from the store
        let fetchRequest: NSFetchRequest<PinLocation> = PinLocation.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            //sesrch for the clicked pin
            for pin in result {
                if pin.latitude == latitude && pin.longitude == longitude {
                    //set it to the local pin properties
                    print ("Pin found and set: \(pin)")
                    self.pinLocations = pin
                    self.performSegue(withIdentifier: "showFlickrPhoto", sender: nil)
                    break
                }
            }
        }
    }
}
