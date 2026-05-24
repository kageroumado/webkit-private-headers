# webkit-private-headers

A curated, documented set of WebKit private headers for macOS, packaged as a Swift Package — plus the Swift sugar to use them without selector-string footguns.

WebKit's public API doesn't expose everything Safari uses. If you've ever needed to mute a tab's audio, observe whether a page is playing media, get the sampled color from the top of a page, drive Force Touch link previews, or watch the web process lifecycle, you've found a wall. These APIs exist — they're just `_underscored` and undocumented. Most projects scrape them from the [WebKit source tree](https://github.com/WebKit/WebKit) by hand. This is that scrape: cleaned up, annotated with availability and nullability, and packaged.

> [!IMPORTANT]
> These APIs are **not allowed in App Store submissions.** This package is for browsers, dev tools, and other apps distributed outside the App Store.

## What's in the box

### `CWebKitPrivate` — the headers themselves

Import directly if you want raw access:

```swift
import CWebKitPrivate
```

Each header is sourced from WebKit trunk and carries `API_AVAILABLE`, audited nullability, and a comment explaining what every type does:

| Header | Covers |
|---|---|
| `WKWebViewPrivate+Core.h` | Page lifecycle, presentation updates, reload variants, preconnect |
| `WKWebViewPrivate+Media.h` | Audio state, page muting, display capture, PiP, media sessions |
| `WKWebViewPrivate+Interaction.h` | Event blocking (`_ignoresAllEvents` etc.) |
| `WKContextMenuPrivate.h` | `_WKHitTestResult`, `_WKContextMenuElementInfo`, QR code payloads |
| `WKDelegatesPrivate.h` | `_WKInputDelegate`, `_WKIconLoadingDelegate`, `WKHistoryDelegatePrivate` |
| `WKThumbnailViewPrivate.h` | `_WKThumbnailView` for efficient tab previews |
| `WKProcessStatePrivate.h` | `_WKWebProcessState` (suspended/foreground/background/notRunning) |
| `WKProcessPoolPrivate.h` | Per-process memory metrics |
| `WKInspectorPrivate.h` | `_WKInspector` Web Inspector control |
| `WKWebAuthenticationPrivate.h` | Passkey panels |
| `WKTextExtractionPrivate.h` | Native content tree access |
| `WKWebViewEditorStatePrivate.h` | Editor state observation for autofill |
| `WKOpenPanelParametersPrivate.h` | File input policy |
| `WKWebpagePreferencesPrivate.h` | Per-navigation autoplay policy |
| `QuartzCoreSPI.h`, `CAContextPrivate.h` | `CAPortalLayer`, `CALayerHost`, cross-window portals |
| `WKProcessPoolBridge.{h,m}` | Wraps deprecated static methods on `WKProcessPool` |

### `WebKitPrivate` — the Swift sugar

Higher-level wrappers that turn private APIs into things you'd actually call:

```swift
import WebKitPrivate
import WebKit

// Audio state with Swift Observation
let audio = WKWebViewAudioObserver()
audio.observe(webView)
// audio.isPlaying, audio.isMuted now bind cleanly in SwiftUI

// Mute control that preserves other flags
webView.setAudioMuted(true)
webView.toggleAudioMute()

// Async/await wrappers around completion-handler APIs
await webView.waitForPresentationUpdate()
let pdf = try await webView.takePDFSnapshot()
let (title, artist) = await webView.nowPlayingInfo()
await webView.setDisplayCaptureState(.active)

// Process state monitoring (macOS 15.4+)
let process = WKWebViewProcessObserver()
process.observe(webView)
if process.needsReload { /* tab was discarded by the OS */ }
```

## Why a curated package vs. copy-pasting

Every multi-tab WebKit project ends up with a `_underscored.h` folder of its own. Each of those scrapes has its own subtle bugs: a missing `API_AVAILABLE`, wrong nullability, an `NS_ENUM` declared as `NS_OPTIONS`, a property that exists on iOS but not macOS, a selector that was renamed two macOS releases ago. The reason this package exists is to absorb that drift in one place:

- Every type carries `API_AVAILABLE` so the compiler enforces version gates.
- Nullability is annotated and audited.
- Every type has a comment explaining what it's for and which WebKit source file it came from.
- The Swift wrappers handle the parts that are easy to get wrong — like clearing one mute flag without clobbering the others, or bridging the no-completion-handler thumbnail API to async/await.

## Installation

Requires macOS 15. (`WKWebView+Observation` uses `Synchronization.Mutex`, which is macOS 15+.)

```swift
dependencies: [
    .package(url: "https://github.com/kageroumado/webkit-private-headers", from: "1.0.0"),
],
targets: [
    .target(name: "App", dependencies: [
        .product(name: "WebKitPrivate", package: "webkit-private-headers"),
    ]),
],
```

## Caveats

Private APIs change. Pin a version. Test against new macOS releases.

A few non-obvious behaviors that bit us first:

- KVO on `_webProcessState` only fires when observers are registered. WebKit's bookkeeping is observer-aware — if nobody's listening, it doesn't broadcast. The included `WebKitObservationBag` handles this correctly.
- `_setPageMuted:` does not trigger KVO on `_mediaMutedState`. Call `WKWebViewAudioObserver.refresh()` after programmatic mute changes.
- `_isPlayingAudio` *does* fire KVO normally — these things are not consistent across the surface.

## Verified against

WebKit trunk as of **December 2024**. Each release of this package re-verifies against a known WebKit commit; check `CHANGELOG.md` for the exact commit hash.

## In production

Used by [Refrax](https://github.com/kageroumado/refrax), a WebKit-based browser for macOS — including the audio observation that powers tab speaker icons, the process-state monitoring behind "tab was suspended" indicators, and the `CAPortalLayer` mirroring used to show the same tab in multiple windows. Refrax uses essentially every header in this package in anger; this is the cleaned-up extraction.

## Acknowledgements

All header declarations are derived from the [WebKit source tree](https://github.com/WebKit/WebKit) — the canonical reference for what these APIs actually do.

## License

[MIT](LICENSE).
