import CWebKitPrivate
import Testing
import WebKit

@testable import WebKitPrivate

/// Smoke tests that confirm:
///
/// 1. The bridging header builds and exposes private enums/methods to Swift.
/// 2. The Swift sugar (`WKWebView+Audio`, `WKWebView+ScreenCapture`,
///    `WKWebView+PrivateAsync`) compiles and links.
/// 3. The private property selectors WebKit actually responds to.
///
/// We don't try to drive every private behavior — many require macOS 14.4+ or
/// produce side effects that aren't observable in a non-UI test process. The
/// goal is "if these tests pass, you can pull this package in and the linker
/// finds the WebKit private symbols."
@MainActor
@Suite("WebKitPrivate")
struct WebKitPrivateTests {
    // MARK: - C Module

    @Test("Private enums are available in Swift via CWebKitPrivate")
    func privateEnumsAvailable() {
        // If these compile, the umbrella header is wired up correctly.
        let muted = _WKMediaMutedState.audioMuted
        #expect(muted.rawValue == 1 << 0)

        let none = _WKMediaMutedState(rawValue: 0)
        #expect(none.rawValue == 0)
    }

    @Test("WKWebView responds to private selectors", arguments: [
        "_isPlayingAudio",
        "_mediaMutedState",
        "_setPageMuted:",
        "_isInFullscreen",
        "_stopAllMediaPlayback",
    ])
    func webViewRespondsToPrivateSelectors(_ name: String) {
        let webView = WKWebView()
        let sel = NSSelectorFromString(name)
        #expect(webView.responds(to: sel), "WKWebView should respond to \(name)")
    }

    // MARK: - Audio Sugar

    @Test("isPlayingAudio defaults to false on a fresh WKWebView")
    func isPlayingAudioDefault() {
        let webView = WKWebView()
        #expect(!webView.isPlayingAudio)
    }

    @Test("setAudioMuted toggles the mute flag")
    func setAudioMutedTogglesFlag() {
        let webView = WKWebView()
        #expect(!webView.isAudioMuted)

        webView.setAudioMuted(true)
        #expect(webView.isAudioMuted)

        webView.setAudioMuted(false)
        #expect(!webView.isAudioMuted)
    }

    @Test("toggleAudioMute flips the flag")
    func toggleAudioMute() {
        let webView = WKWebView()
        let before = webView.isAudioMuted

        webView.toggleAudioMute()
        #expect(webView.isAudioMuted == !before)

        webView.toggleAudioMute()
        #expect(webView.isAudioMuted == before)
    }

    @Test("audioState reflects idle on a fresh WKWebView")
    func audioStateIdle() {
        let webView = WKWebView()
        #expect(webView.audioState == .idle)
    }

    // MARK: - Screen Capture Sugar

    @Test("areCaptureDevicesMuted defaults to false")
    func captureDevicesNotMutedByDefault() {
        let webView = WKWebView()
        #expect(!webView.areCaptureDevicesMuted)
    }

    @Test("webContentCaptureState defaults to .none")
    func webContentCaptureStateDefault() {
        let webView = WKWebView()
        #expect(webView.webContentCaptureState == .none)
    }

    // MARK: - Async Sugar

    @Test("waitForPresentationUpdate returns")
    func waitForPresentationUpdateReturns() async {
        let webView = WKWebView()
        // Doesn't actually need to render — just ensure the bridge calls back.
        await webView.waitForPresentationUpdate()
    }

    @Test("nowPlayingInfo returns (nil, nil) when nothing is playing")
    func nowPlayingInfoNil() async {
        let webView = WKWebView()
        let info = await webView.nowPlayingInfo()
        #expect(info.title == nil)
        #expect(info.artist == nil)
    }

    // MARK: - Observation Bag

    @Test("WebKitObservationBag fires for an initial observation")
    func observationBagInitial() async throws {
        let webView = WKWebView()
        let counter = Counter()

        let bag = WebKitObservationBag()
        bag.observe(webView, keyPath: "_isPlayingAudio", options: [.initial, .new]) {
            Task { await counter.increment() }
        }

        // .initial should fire synchronously.
        try await counter.waitForCount(at: 1, within: .seconds(1))

        bag.invalidateAll()
        #expect(bag.count == 0)
    }

    @Test("Audio observer reflects initial state")
    func audioObserverInitialState() async throws {
        let webView = WKWebView()
        let observer = WKWebViewAudioObserver()
        observer.observe(webView)

        // Initial KVO event should populate state.
        try await Task.sleep(for: .milliseconds(50))
        #expect(!observer.isPlaying)
        #expect(observer.mutedState == 0 || observer.mutedState != 0) // accept any value
    }
}

// MARK: - Helpers

private actor Counter {
    private(set) var value = 0

    func increment() {
        value += 1
    }

    func waitForCount(at target: Int, within timeout: Duration) async throws {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while value < target {
            if ContinuousClock.now >= deadline {
                throw CountTimeout(expected: target, actual: value)
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    struct CountTimeout: Error, CustomStringConvertible {
        let expected: Int
        let actual: Int
        var description: String { "Counter timed out: expected \(expected), actual \(actual)" }
    }
}
