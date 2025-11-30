import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  // Shared Flutter engine for the entire app
  lazy var flutterEngine = FlutterEngine(name: "vmurugan_engine")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    print("✅ AppDelegate: didFinishLaunchingWithOptions called")

    // Start the Flutter engine
    flutterEngine.run()
    print("✅ AppDelegate: Flutter engine started")

    // Register plugins with the shared engine
    GeneratedPluginRegistrant.register(with: flutterEngine)
    print("✅ AppDelegate: Plugins registered")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    config.delegateClass = SceneDelegate.self
    return config
  }
}
