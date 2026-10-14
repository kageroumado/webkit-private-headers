# webkit-private-headers

WebKitPrivate exposes macOS WebKit features absent from the public SDK, including tab muting, media state, process state and live thumbnails. The package pairs annotated Objective-C headers with Swift observation and async wrappers.

```swift
.package(url: "https://github.com/kageroumado/webkit-private-headers", from: "1.0.0")
```

## Highlights

- Control tab audio, media state, processes, and thumbnails beyond WebKit’s public API.
- Use annotated Objective-C headers directly or Swift observation and async wrappers.
- Handle WebKit’s observer-registration and mute-refresh quirks through the supplied helpers.

<details>
<summary>Features and API reference</summary>

### APIs

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

### `WebKitPrivate` — Swift wrappers

Swift observation and async wrappers:

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

### Caveats

Private APIs change. Pin a version. Test against new macOS releases.

Observation behavior:

- KVO on `_webProcessState` only fires when observers are registered. WebKit's bookkeeping is observer-aware — if nobody's listening, it doesn't broadcast. The included `WebKitObservationBag` handles this correctly.
- `_setPageMuted:` does not trigger KVO on `_mediaMutedState`. Call `WKWebViewAudioObserver.refresh()` after programmatic mute changes.
- `_isPlayingAudio` *does* fire KVO normally — these things are not consistent across the surface.

### Verified against

WebKit trunk as of **December 2024**. Each release of this package re-verifies against a known WebKit commit; check `CHANGELOG.md` for the exact commit hash.

### Acknowledgements

All header declarations are derived from the [WebKit source tree](https://github.com/WebKit/WebKit) — the canonical reference for what these APIs actually do.

</details>

## Notes

- Swift Package Manager product: `WebKitPrivate`.
- macOS 15+; private APIs are unsuitable for App Store submissions and may change between macOS releases.
