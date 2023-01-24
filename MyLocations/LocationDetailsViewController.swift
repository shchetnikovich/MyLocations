import UIKit
import CoreLocation
import CoreData

private let dateFormatter: DateFormatter = {        //  Ускорям работу приложения замыканием, сразу создаем экземпляр даты-пикера с предварительными стилями
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
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var addPhotoLabel: UILabel!
    @IBOutlet var imageHeight: NSLayoutConstraint!
    
    
    var coordinate = CLLocationCoordinate2D(
        latitude: 0,
        longitude: 0)       //  Координаты, не? поэтому init value 0 - 0
    var placemark: CLPlacemark?
    
    var categoryName = "Без категории"
    
    var managedObjectContext: NSManagedObjectContext!
    var date = Date()
    
    var locationToEdit: Location? {
        didSet {
            if let location = locationToEdit {
                descriptionText = location.locationDescription
                categoryName = location.category
                date = location.date
                coordinate = CLLocationCoordinate2DMake(
                    location.latitude,
                    location.longitude)
                placemark = location.placemark
            }
        }
    }
    
    var descriptionText = ""
    
    var image: UIImage?
    
    var observer: Any!      //  Hold reference to the observer
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let location = locationToEdit {
            title = "Редактировать локацию"
        }
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        latitudeLabel.text = String( format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String( format: "%.8f", coordinate.longitude)
        if let placemark = placemark {
            addressLabel.text = string(from: placemark)
        } else {
            addressLabel.text = "Адрес не найден"
        }
        dateLabel.text = format(date: date)
        
        // Скрываем keyboard
        let gestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
        
        listenForBackgroundNotification()
    }
    
    deinit {
      print("*** deinit \(self)")
      NotificationCenter.default.removeObserver(observer!)
    }
    
    // MARK: - Table View Delegates
    
    override func tableView(
        _ tableView: UITableView,
        willSelectRowAt indexPath: IndexPath
    ) -> IndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 {
            return indexPath
        } else {
            return nil
        }
    }
    
    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath ){
            if indexPath.section == 0 && indexPath.row == 0 {
                descriptionTextView.becomeFirstResponder()
            } else if indexPath.section == 1 && indexPath.row == 0 {
                tableView.deselectRow(at: indexPath, animated: true)
                pickPhoto()
            }
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
    
    @objc func hideKeyboard(
        _ gestureRecognizer: UIGestureRecognizer
    ){
        let point = gestureRecognizer.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        if indexPath != nil && indexPath!.section == 0 &&
            indexPath!.row == 0 {
            return
        }
        descriptionTextView.resignFirstResponder()
    }
    
    func show(image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        addPhotoLabel.text = ""
        imageHeight.constant = 260
        tableView.reloadData()
    }
    
    func listenForBackgroundNotification() {        //  Handle background mode
        observer = NotificationCenter.default.addObserver(
            forName: UIScene.didEnterBackgroundNotification,
            object: nil,
            queue: OperationQueue.main) { [weak self] _ in
                if let weakSelf = self {
                    if weakSelf.presentedViewController != nil {
                        weakSelf.dismiss(animated: false, completion: nil)
                    }
                    weakSelf.descriptionTextView.resignFirstResponder()
                }
            }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender:
                          Any?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destination as!
            CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func done() {
        guard let mainView = navigationController?.parent?.view
        else { return }
        let hudView = HudView.hud(inView: mainView, animated: true)
        
        let location: Location
        if let temp = locationToEdit {
            hudView.text = "Обновлено"
            location = temp
        } else {
            hudView.text = "Записано"
            location = Location(context: managedObjectContext)
        }
        
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        
        do {
            try managedObjectContext.save()
            afterDelay(0.6)
            {
                hudView.hide()
                self.navigationController?.popViewController(animated: true)
            }
        } catch {
            fatalCoreDataError(error)
        }
    }
    
    @IBAction func cancel() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func categoryPickerDidPickCategory(
        _ segue: UIStoryboardSegue
    ){
        let controller = segue.source as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
}

extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Image Helper Methode
    
    func takePhotoWithCamera() {
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Image Picker Delegates
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info:
        [UIImagePickerController.InfoKey: Any]
    ){
        image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        
        if let theImage = image {
            show(image: theImage)
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(
        _ picker: UIImagePickerController
    ){
        dismiss(animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func pickPhoto() {
      if UIImagePickerController.isSourceTypeAvailable(.camera) {
        showPhotoMenu()
      } else {
        choosePhotoFromLibrary()
      }
    }
    
    func showPhotoMenu() {
      let alert = UIAlertController(
        title: nil,
        message: nil,
        preferredStyle: .actionSheet)
      let actCancel = UIAlertAction(
        title: "Отмена",
        style: .cancel,
        handler: nil)
      alert.addAction(actCancel)
      let actPhoto = UIAlertAction(
        title: "Сделать фотографию",
        style: .default) { _ in
            self.takePhotoWithCamera()
        }
      alert.addAction(actPhoto)
      let actLibrary = UIAlertAction(
        title: "Выбрать из Галереи",
        style: .default) { _ in
            self.choosePhotoFromLibrary()
        }
          alert.addAction(actLibrary)
          present(alert, animated: true, completion: nil)
        }
}
