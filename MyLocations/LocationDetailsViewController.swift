import UIKit
import CoreLocation

private let dateFormatter: DateFormatter = {        //  Ускорям работу приложения приватной константой
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

class LocationDetailsViewController: UITableViewController {
    
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var latitudeLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    
    var coordinate = CLLocationCoordinate2D(
        latitude: 0,
        longitude: 0)       //  Координаты, не? поэтому init value 0 - 0
    var placemark: CLPlacemark?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionTextView.text = ""
        categoryLabel.text = ""
        latitudeLabel.text = String( format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String( format: "%.8f", coordinate.longitude)
        if let placemark = placemark {
            addressLabel.text = string(from: placemark)
        } else {
            addressLabel.text = "Адрес не найден"
        }
        dateLabel.text = format(date: Date())
    }

    
    // MARK: - Helper Methods
    
    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    func string(from placemark: CLPlacemark) -> String {
        var text = ""
        if let tmp = placemark.subThoroughfare {
            text += tmp + " "
        }
        if let tmp = placemark.thoroughfare {
            text += tmp + ", "
        }
        if let tmp = placemark.locality {
            text += tmp + ", "
        }
        if let tmp = placemark.administrativeArea {
            text += tmp + " "
        }
        if let tmp = placemark.postalCode {
            text += tmp + ", "
        }
        if let tmp = placemark.country {
            text += tmp
        }
        return text
    }
    

    
    // MARK: - Actions
    
    @IBAction func done() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancel() {
        navigationController?.popViewController(animated: true)
    }
    
}
