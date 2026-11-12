import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// Shares a file together with a text: the share_plus plugin drops the text when it shares
  /// files on macOS, so the app opens the system share picker itself.
  private var shareChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "hitwave/share",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak flutterViewController] call, result in
      guard call.method == "shareFile",
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String,
        let view = flutterViewController?.view
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      var items: [Any] = []
      if let text = args["text"] as? String, !text.isEmpty {
        items.append(text)
      }
      items.append(NSURL.fileURL(withPath: path))
      let picker = NSSharingServicePicker(items: items)
      let origin = NSRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
      picker.show(relativeTo: origin, of: view, preferredEdge: .minY)
      result(nil)
    }
    shareChannel = channel

    super.awakeFromNib()
  }
}
