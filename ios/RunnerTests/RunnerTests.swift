import AVFoundation
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {
  @MainActor
  func testEqualizerReceivesDecodedAudioFromAVPlayer() throws {
    let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)!
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 48000)!
    buffer.frameLength = 48000
    for channel in 0..<2 {
      for frame in 0..<48000 { buffer.floatChannelData![channel][frame] = Float(sin(Double(frame) * 2 * .pi * 230 / 48000) * 0.1) }
    }
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("aura-eq-test.wav")
    try AVAudioFile(forWriting: url, settings: format.settings).write(from: buffer)
    defer { try? FileManager.default.removeItem(at: url) }
    try AVAudioSession.sharedInstance().setCategory(.playback)
    try AVAudioSession.sharedInstance().setActive(true)
    XCTAssertEqual(AppDelegate.equalizerDiagnostics()["supported"] as? Bool, true)
    let item = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: item)
    player.volume = 0
    let processed = expectation(description: "Native EQ receives Float32 frames")
    let observation = item.observe(\.status, options: [.initial, .new]) { item, _ in
      if item.status == .readyToPlay {
        DispatchQueue.main.async {
          NotificationCenter.default.post(name: Notification.Name("AuraAudioItemReady"), object: item)
          player.play()
        }
      }
    }
    let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
      let state = AppDelegate.equalizerDiagnostics()
      if state["attached"] as? Bool == true, (state["frames"] as? NSNumber)?.intValue ?? 0 > 0 {
        timer.invalidate(); processed.fulfill()
      }
    }
    wait(for: [processed], timeout: 8)
    timer.invalidate(); observation.invalidate(); player.pause()
  }
}
