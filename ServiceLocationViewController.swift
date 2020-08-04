//
//  ServiceLocationViewController.swift
//  Smds_app
//
//  Created by Asha Jain on 6/23/20.
//  Copyright © 2020 groupproject. All rights reserved.
//

import Foundation
import UIKit
import MapKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ServiceLocationViewController: UIViewController, CLLocationManagerDelegate {
    
    
    @IBOutlet var mapView: MKMapView!
    var allServiceLocations : [ServiceLocation] = []
    let defaultCenterLatitude = 30.2895659
    let defaultCenterLongitude = -97.739267
    let locationManager = CLLocationManager()
    let serviceLocationMarker = "marker"
    let radius = CLLocationDistance(exactly: 1500.0)
    var resultSearchController:UISearchController? = nil
    var selectedPin:MKPlacemark? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        mapView.delegate = self
        mapView.register(ServiceLocationMarkerView.self, forAnnotationViewWithReuseIdentifier: serviceLocationMarker)
        setupView()
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier:     "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable as UISearchResultsUpdating
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        
    }
    
    func setupView(){
        self.loadViewIfNeeded()
        self.navigationController?.title = "Active Service Locations"
        let slService = ServiceLocationService()
        slService.getServiceLocations(nil) { locations in
            if let locations = locations {
                self.allServiceLocations = locations
                self.updateMap()
            }
        }
        
        let center = self.averageCoordinate()
        
        self.mapView.centerToLocation(CLLocation.init(latitude: center.latitude, longitude: center.longitude), regionRadius: self.radius!)
        
    }
    
    func updateMap(){
        var annotations: [CustomAnnotation] = []
        for location in allServiceLocations {
            
            let type : AnnotationType
            
            switch location.locationType{
            case .dorm:
                type = AnnotationType.dorm
            case .officebuilding:
                type = AnnotationType.officebuilding
            case .library:
                type = AnnotationType.library
            case .restaurant:
                type = AnnotationType.restaurant
            case .other:
                type = AnnotationType.other
            }
            let annotation = CustomAnnotation(title: "\(location.locationName)", locationName: "\(location.locationType)", coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude), type: type)
            annotations.append(annotation)
        }
        let centerLocation = self.averageCoordinate()
        DispatchQueue.main.async {
            self.mapView.centerToLocation(CLLocation.init(latitude: centerLocation.latitude, longitude: centerLocation.longitude), regionRadius: self.radius!)
            self.mapView.addAnnotations(annotations)
        }
    }
    
    func averageCoordinate () -> CLLocationCoordinate2D {
        var sumLatitude :Double = 0
        var sumLongitude:Double = 0
        var totalNum: Double = 0
        
        for location in allServiceLocations{
            if(location.latitude != 0.0 && location.longitude != 0.0){
                sumLatitude += location.latitude
                sumLongitude += location.longitude
                totalNum += 1.0
            }
        }
        
        var averageLatitude = sumLatitude / totalNum
        var averageLongitude = sumLongitude / totalNum
        if (averageLatitude == 0.0 || averageLongitude == 0.0 || totalNum == 0.0) {
            averageLongitude = defaultCenterLongitude
            averageLatitude = defaultCenterLatitude
        }
        return CLLocationCoordinate2D(latitude: averageLatitude, longitude: averageLongitude)
    }
    
    
}
extension ServiceLocationViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is CustomAnnotation else {return nil}
        
        
        var view = ServiceLocationMarkerView()
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: serviceLocationMarker) as? ServiceLocationMarkerView{
            annotationView.annotation = annotation
            view = annotationView
            view.frame.size = CGSize(width: 60, height: 60)
        }
        else{
            view = ServiceLocationMarkerView(
                annotation: annotation,
                reuseIdentifier: serviceLocationMarker)
            view.canShowCallout = false
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.frame.size = CGSize(width: 30, height: 40)
            
            let switchButton = UISwitch()
            switchButton.isOn = true
            switchButton.onTintColor = .green
            switchButton.largeContentTitle = "Active"
            view.rightCalloutAccessoryView = switchButton
        }
        return view
    }
    
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard (view.annotation as? CustomAnnotation) != nil else {
            return
        }
        
        print("Callout Tapped")
    }
    
}
extension ServiceLocationViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
    UIView.animate(withDuration: 1.5, animations: { () -> Void in
       let center = CLLocationCoordinate2D(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude )
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.mapView.setRegion(region, animated: true)
    })
}
}
