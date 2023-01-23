import UIKit
import CoreData




class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    lazy var persistentContainer: NSPersistentContainer = {     //  Load Data Model
        let container = NSPersistentContainer(name: "MyLocations")
        container.loadPersistentStores {_, error in
            if let error = error {
                fatalError("Could not load data store: \(error)")
            }
        }
        return container
    }()
    
    lazy var managedObjectContext = persistentContainer.viewContext
    
    var window: UIWindow?
    
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ){
        let tabController = window!.rootViewController as! UITabBarController
        if let tabViewControllers = tabController.viewControllers {
            
            var navController = tabViewControllers[0] as! UINavigationController
            
            let controller1 = navController.viewControllers.first as! CurrentLocationViewController
            controller1.managedObjectContext = managedObjectContext
            
            navController = tabViewControllers[1] as! UINavigationController
            
            let controller2 = navController.viewControllers.first as! LocationsViewController
            controller2.managedObjectContext = managedObjectContext
            
            
            
            listenForFatalCoreDataNotifications()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        saveContext()
    }
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Helper methods
    
    func listenForFatalCoreDataNotifications() {
        
        NotificationCenter.default.addObserver(
            forName: dataSaveFailedNotification,
            object: nil,
            queue: OperationQueue.main
        ) { _ in
            let message = """
          There was a fatal error in the app and it cannot continue.
    Press OK to terminate the app. Sorry for the inconvenience.
    """
            
            let alert = UIAlertController(
                title: "Internal Error",
                message: message,
                preferredStyle: .alert)
            
            let action = UIAlertAction(title: "OK", style: .default) {
                _ in
                let exception = NSException(
                    name: NSExceptionName.internalInconsistencyException,
                    reason: "Fatal Core Data Error",
                    userInfo: nil)
                exception.raise()
            }
            alert.addAction(action)
            
            let tabController = self.window!.rootViewController!
            tabController.present( alert, animated: true, completion: nil)
            
        }
    }
}
