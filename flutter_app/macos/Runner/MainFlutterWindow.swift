import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let desktopSize = CGSize(width: 1100, height: 750)
    let screenSize  = NSScreen.main?.visibleFrame.size ?? desktopSize
    let origin = CGPoint(
      x: (screenSize.width  - desktopSize.width)  / 2,
      y: (screenSize.height - desktopSize.height) / 2
    )
    let windowFrame = CGRect(origin: origin, size: desktopSize)
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.minSize = CGSize(width: 400, height: 600)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
