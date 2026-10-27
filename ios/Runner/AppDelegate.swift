import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AuraNativeUI") {
      AuraNativeUI.register(with: registrar)
    }
  }
}


// Real UIKit Liquid Glass, embedded through Flutter platform views.
// No image filters or shader approximations are used by these controls.
final class AuraNativeUI: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "aura/native_ui", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "capabilities" else { result(FlutterMethodNotImplemented); return }
      if #available(iOS 26.0, *) { result(["liquidGlass": true]) }
      else { result(["liquidGlass": false]) }
    }
    registrar.register(AuraControlFactory(messenger: registrar.messenger(), kind: "dock"), withId: "aura/native_dock")
    registrar.register(AuraControlFactory(messenger: registrar.messenger(), kind: "button"), withId: "aura/native_button")
  }
}

final class AuraControlFactory: NSObject, FlutterPlatformViewFactory {
  let messenger: FlutterBinaryMessenger
  let kind: String
  init(messenger: FlutterBinaryMessenger, kind: String) { self.messenger = messenger; self.kind = kind }
  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol { FlutterStandardMessageCodec.sharedInstance() }
  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
    AuraControl(frame: frame, id: viewId, kind: kind, messenger: messenger, config: args as? [String: Any] ?? [:])
  }
}

final class AuraControl: NSObject, FlutterPlatformView {
  private let root: AuraControlView
  private let channel: FlutterMethodChannel
  init(frame: CGRect, id: Int64, kind: String, messenger: FlutterBinaryMessenger, config: [String: Any]) {
    channel = FlutterMethodChannel(name: "aura/native_\(kind)/\(id)", binaryMessenger: messenger)
    root = AuraControlView(frame: frame, kind: kind)
    super.init()
    root.send = { [weak self] method, value in self?.channel.invokeMethod(method, arguments: value) }
    root.update(config)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "update", let config = call.arguments as? [String: Any] { self?.root.update(config); result(nil) }
      else { result(FlutterMethodNotImplemented) }
    }
  }
  func view() -> UIView { root }
  deinit { channel.setMethodCallHandler(nil) }
}

final class AuraControlView: UIView {
  let kind: String
  var send: ((String, Any?) -> Void)?
  private let mini: UIVisualEffectView
  private let navigation: UIVisualEffectView
  private let titleLabel = UILabel(), artistLabel = UILabel()
  private let cover = UIImageView()
  private let progress = UIProgressView(progressViewStyle: .bar)
  private let open = UIButton(type: .custom), play = UIButton(type: .system), skipButton = UIButton(type: .system)
  private let single = UIButton(type: .system)
  private var tabs: [UIButton] = []
  private var artworkURL = ""
  private var imageTask: URLSessionDataTask?
  private var config: [String: Any] = [:]

  private static func material() -> UIVisualEffect {
    if #available(iOS 26.0, *) {
      let effect = UIGlassEffect(style: .regular)
      effect.isInteractive = true
      return effect
    }
    return UIBlurEffect(style: .systemMaterial)
  }
  init(frame: CGRect, kind: String) {
    self.kind = kind
    mini = UIVisualEffectView(effect: Self.material())
    navigation = UIVisualEffectView(effect: Self.material())
    super.init(frame: frame)
    backgroundColor = .clear
    isOpaque = false
    if kind == "button" {
      addSubview(single)
      single.addAction(UIAction { [weak self] _ in self?.send?("pressed", nil) }, for: .touchUpInside)
    } else {
      addSubview(mini); addSubview(navigation)
      for surface in [mini, navigation] { surface.layer.cornerRadius = 28; surface.clipsToBounds = true }
      cover.contentMode = .scaleAspectFill; cover.clipsToBounds = true; cover.layer.cornerRadius = 9
      cover.backgroundColor = .tertiarySystemFill
      titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
      artistLabel.font = .systemFont(ofSize: 12); artistLabel.textColor = .secondaryLabel
      titleLabel.lineBreakMode = .byTruncatingTail; artistLabel.lineBreakMode = .byTruncatingTail
      for view in [cover, titleLabel, artistLabel, progress, open, play, skipButton] { mini.contentView.addSubview(view) }
      progress.trackTintColor = .clear; progress.progressTintColor = .label.withAlphaComponent(0.5)
      open.accessibilityLabel = "Apri player"
      open.addAction(UIAction { [weak self] _ in self?.send?("open", nil) }, for: .touchUpInside)
      play.addAction(UIAction { [weak self] _ in self?.send?("play", nil) }, for: .touchUpInside)
      skipButton.addAction(UIAction { [weak self] _ in self?.send?("next", nil) }, for: .touchUpInside)
      skipButton.accessibilityLabel = "Brano successivo"
      let symbols = ["play.square", "magnifyingglass", "square.stack"]
      let labels = ["Ascolta", "Cerca", "Libreria"]
      for index in 0..<3 {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: symbols[index])
        configuration.title = labels[index]
        configuration.imagePlacement = .top; configuration.imagePadding = 4
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
          var attributes = incoming; attributes.font = UIFont.systemFont(ofSize: 11, weight: .medium); return attributes
        }
        button.configuration = configuration
        button.accessibilityLabel = labels[index]
        button.addAction(UIAction { [weak self] _ in self?.send?("tab", index) }, for: .touchUpInside)
        navigation.contentView.addSubview(button); tabs.append(button)
      }
    }
  }
  required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
  override func layoutSubviews() {
    super.layoutSubviews()
    if kind == "button" { single.frame = bounds; return }
    let width = bounds.width
    mini.frame = CGRect(x: 0, y: 0, width: width, height: 56)
    navigation.frame = CGRect(x: 0, y: mini.isHidden ? 0 : 66, width: width, height: 66)
    cover.frame = CGRect(x: 8, y: 8, width: 40, height: 40)
    titleLabel.frame = CGRect(x: 60, y: 9, width: max(0, width - 164), height: 20)
    artistLabel.frame = CGRect(x: 60, y: 30, width: max(0, width - 164), height: 17)
    open.frame = CGRect(x: 0, y: 0, width: max(0, width - 100), height: 56)
    play.frame = CGRect(x: width - 98, y: 4, width: 46, height: 48)
    skipButton.frame = CGRect(x: width - 52, y: 4, width: 46, height: 48)
    progress.frame = CGRect(x: 20, y: 54, width: max(0, width - 40), height: 2)
    let tabWidth = (width - 12) / 3
    for (i, button) in tabs.enumerated() { button.frame = CGRect(x: 6 + CGFloat(i) * tabWidth, y: 5, width: tabWidth, height: 56) }
  }
  func update(_ data: [String: Any]) {
    config = data
    overrideUserInterfaceStyle = data["dark"] as? Bool == true ? .dark : .light
    let accent = UIColor(red: 0.65, green: 0.69, blue: 0.98, alpha: 1)
    if kind == "button" {
      var style: UIButton.Configuration
      if #available(iOS 26.0, *) { style = .glass() } else { style = .plain() }
      style.image = UIImage(systemName: data["symbol"] as? String ?? "ellipsis")
      style.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
      style.baseForegroundColor = data["active"] as? Bool == true ? accent : .label
      single.configuration = style
      single.isEnabled = data["enabled"] as? Bool ?? true
      single.accessibilityLabel = data["label"] as? String
    } else {
      mini.isHidden = data["hasCurrent"] as? Bool == false
      let title = data["title"] as? String ?? ""
      titleLabel.text = title; artistLabel.text = data["artist"] as? String
      open.accessibilityLabel = "Apri player: \(title)"
      let playing = data["playing"] as? Bool ?? false
      let busy = data["busy"] as? Bool ?? false
      play.setImage(UIImage(systemName: playing ? "pause.fill" : "play.fill"), for: .normal)
      play.accessibilityLabel = playing ? "Pausa" : "Riproduci"
      play.isEnabled = !busy; skipButton.isEnabled = !busy
      play.tintColor = .label; skipButton.tintColor = .label
      skipButton.setImage(UIImage(systemName: "forward.end.fill"), for: .normal)
      progress.progress = Float((data["progress"] as? Double ?? 0).clamped(to: 0...1))
      let selected = data["tab"] as? Int ?? 0
      for (index, tab) in tabs.enumerated() {
        tab.tintColor = index == selected ? accent : .secondaryLabel
        tab.accessibilityTraits = index == selected ? [.button, .selected] : [.button]
        tab.backgroundColor = index == selected ? accent.withAlphaComponent(0.13) : .clear
        tab.layer.cornerRadius = 24
      }
      let url = data["artwork"] as? String ?? ""
      if url != artworkURL {
        artworkURL = url; imageTask?.cancel()
        cover.image = UIImage(systemName: "music.note")
        if let remote = URL(string: url), remote.scheme == "https" {
          imageTask = URLSession.shared.dataTask(with: remote) { [weak self] bytes, _, _ in
            guard let bytes = bytes, let image = UIImage(data: bytes) else { return }
            DispatchQueue.main.async { if self?.artworkURL == url { self?.cover.image = image } }
          }
          imageTask?.resume()
        }
      }
    }
    setNeedsLayout()
  }
  deinit { imageTask?.cancel() }
}
private extension Double {
  func clamped(to limits: ClosedRange<Double>) -> Double { min(max(self, limits.lowerBound), limits.upperBound) }
}
