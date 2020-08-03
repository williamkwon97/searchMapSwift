//
//  LocationSearchTable.swift
//  Smds_app
//
//  Created by William Kwon on 8/2/20.
//  Copyright © 2020 groupproject. All rights reserved.
//

import Foundation
import UIKit
import MapKit
class LocationSearchTable: UITableViewController {
    
    var handleMapSearchDelegate:HandleMapSearch? = nil
    var matchingItems: [MKMapItem] = []
    var mapView: MKMapView?
    var allServiceLocations : [ServiceLocation] = []
    
    func parseAddress(selectedItem:MKPlacemark) -> String {
        
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil &&
            selectedItem.thoroughfare != nil) ? " " : ""
        
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) &&
            (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil &&
            selectedItem.administrativeArea != nil) ? " " : ""
        
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        
        return addressLine
    }
}

extension LocationSearchTable : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView,
            let searchBarText = searchController.searchBar.text else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        
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
        
        
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}

extension LocationSearchTable {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
        return cell
    }
    
}

extension LocationSearchTable {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        handleMapSearchDelegate?.dropPinZoomIn(placemark: selectedItem)
        dismiss(animated: true, completion: nil)
    }
}
