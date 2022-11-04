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
    var pinLocations: [PinLocation] = []
    var annotation: MKAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        if let result = try? dataController.viewContext.fetch(fetchRequest) {
            pinLocations = result
        }
        addAnnotations()
    }
    
    @objc func handleTap(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizer.State.ended {
            return
        } else if gestureRecognizer.state != UIGestureRecognizer.State.began {
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
    }
    
    func addAnnotations(){
        mapView.removeAnnotations(mapView.annotations)
        var annotations = [MKPointAnnotation]()
        for pinLocation in pinLocations {
            let latitude = CLLocationDegrees(pinLocation.latitude)
            let longitude = CLLocationDegrees(pinLocation.longitude)
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
}

extension MapViewController {
    
    func showErrorAlert(title: String, message: String) {
        let alertViewController = UIAlertController (title: title,  message: message, preferredStyle: .alert)
        alertViewController.addAction(UIAlertAction(title: "Error", style: .default, handler: nil))
        self.present(alertViewController, animated: true, completion: nil)
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let secondView = storyboard?.instantiateViewController( withIdentifier: "showFlickrPhoto") as! PhotoAlbumViewController
        secondView.selectedPin = view.annotation?.coordinate
        secondView.dataController = dataController
        mapView.deselectAnnotation(view.annotation, animated: true)
        self.navigationController?.pushViewController(secondView, animated: true)
    }
}
