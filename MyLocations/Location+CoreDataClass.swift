import Foundation
import CoreData
import MapKit


@objc(Location)
public class Location: NSManagedObject, MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    public var title: String? {
        if locationDescription.isEmpty {
            return "Пусто"
        } else {
            return locationDescription
        }
    }
    
    public var subtitle: String? {
        return category
    }
}
