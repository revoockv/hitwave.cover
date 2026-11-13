import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// Shares a file under its own name and puts its text on the clipboard: the share_plus
  /// plugin drops the text of a shared file on macOS, and apps given both may drop the file.
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
      // Only the file: an app given a file and a text (Telegram) may send just the text. The text
      // goes onto the clipboard, to paste as the caption.
      var copied = false
      if let text = args["text"] as? String, !text.isEmpty {
        NSPasteboard.general.clearContents()
        copied = NSPasteboard.general.setString(text, forType: .string)
      }
      let picker = NSSharingServicePicker(items: [NSURL.fileURL(withPath: path)])
      let origin = NSRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
      picker.show(relativeTo: origin, of: view, preferredEdge: .minY)
      result(copied)
    }
    shareChannel = channel

    super.awakeFromNib()
  }
}
