import UIKit
import Flutter

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else {
            print("❌ SceneDelegate: windowScene is nil!")
            return
        }

        print("✅ SceneDelegate: windowScene created")

        // Get the shared Flutter engine from AppDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let flutterEngine = appDelegate.flutterEngine

        print("✅ SceneDelegate: Got Flutter engine from AppDelegate")

        // Create FlutterViewController with the shared engine
        let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)

        print("✅ SceneDelegate: Created FlutterViewController")

        // Create and configure window
        window = UIWindow(windowScene: windowScene)
        window?.backgroundColor = .white
        window?.rootViewController = flutterViewController

        print("✅ SceneDelegate: Set rootViewController")

        window?.makeKeyAndVisible()

        print("✅ SceneDelegate: Called makeKeyAndVisible()")
        print("   Window frame: \(window?.frame ?? .zero)")
        print("   Window isHidden: \(window?.isHidden ?? true)")
        print("   Window isKeyWindow: \(window?.isKeyWindow ?? false)")
    }
}
