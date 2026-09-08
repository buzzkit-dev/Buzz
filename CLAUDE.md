# Buzz — the iOS app

Buzz gives every install one endpoint their coding agents POST to: a notification when work
finishes and a Live Activity while it runs. It reports; it is not a remote control. When an agent
is blocked it sets its session `status` to `waiting`, so the phone reads "Waiting on you" and the
person goes to their desk to decide, in their editor, natively. Buzz has no reply path — answering a
harness's approval from the phone could not stay in sync across every tool, and a control that
silently desyncs is worse than none, so Buzz only ever tells you that you are needed.

**buzzkit powers it. Buzz is the app. ping is what you do.**

The backend is `apps/ping` in the buzzkit monorepo (`ping.buzzkit.dev`); everything a person reads
lives at `buzzkit.dev/buzz`. This repository is only the app.

## Structure

```
Buzz.xcodeproj           The project, checked in; targets, entitlements and settings are edited in Xcode
Shared/                  compiled into BOTH targets (the app and the widget extension)
  Activity/
    BuzzActivityAttributes.swift  The wire contract with the server. See "The wire contract" below
    BuzzSamples.swift             The three sample states the preview screen renders
  Networking/
    PingClient.swift              Every call to ping.buzzkit.dev
    BuzzStore.swift               App-group storage: the endpoint and the buzzkit identity
  UI/
    Theme/Theme.swift             `Theme` (the color tokens, `Theme.Radius`) and `Motion` (the timings)
    Theme/Typography.swift        `FontSize`, `Font.typo`, `View.typo` (Open Runde + tracking), `Font.mono`
    Components/Icon.swift         `Icon` (a Central icon by name) and the `iconSwap` modifier
    Components/StatusIndicators.swift  `BuzzStatus.tint` / `.icon`, StatusIcon, StatusDot, StatusTile, ProgressBar
    Components/LockScreenView.swift    The Lock Screen view and its parts, shared so the app can preview them
  Support/Unchecked.swift         @unchecked Sendable box for passing Activity into a Task
  Resources/
    Fonts/                        Open Runde (Regular, Medium, Semibold), registered in both targets
    Icons.xcassets                Central Icons as template SVGs, one imageset per icon name
Buzz/                    the app target (CruiseSignal's layout)
  BuzzApp.swift          The scene: owns PairingModel and restores it
  ContentView.swift      Connect an agent, plus the -BuzzPreviewActivity launch argument
  Models/SampleNotification.swift   The sample pushes the stacks cycle through
  Services/
    Pairing/PairingModel.swift      Pair, restore, rotate, the six-digit code, the notification permission;
                                    configures BuzzKit and identifies; preview models
    Activities/ActivityBinder.swift Reports activity ids and push tokens to the API and the SDK
    Activities/ActivityMonitor.swift Mirrors the running Live Activity's content into the app
  UI/Components/                  AppButton (+ AppButtonStyle, IconButtonStyle), Stage (the brand panel),
                                  NotificationStack + SwappingStack, NotificationCard, CodeDigits, LiveDot +
                                  StatusPill, EndpointField
  Views/
    Home/HomeView.swift               Status pill, the stage (the live activity or the idle stack), the code
    Home/EndpointSheet.swift          The raw endpoint and rotate, behind the menu
    Debug/ActivityPreviewView.swift   DEBUG: renders every Live Activity state without a server
    Debug/ScreenPreviewView.swift     DEBUG: on-device previews from the More menu
  Resources/                      Assets.xcassets (AppIcon, Mark), Info.plist, Buzz.entitlements
BuzzWidget/              the widget extension
  BuzzWidgetBundle.swift
  BuzzLiveActivity.swift The ActivityConfiguration and the Dynamic Island; the Lock Screen view
                         itself comes from Shared/
BuzzNotificationService/ the notification service extension
  NotificationService.swift  Subclasses BuzzKitNotificationService. Apple runs it for every push
                             with mutable-content; it turns each push into a communication
                             notification (INSendMessageIntent) so the Lock Screen shows the agent's
                             avatar, and sends delivered receipts. Compiles Shared/BuzzStore and the
                             agent catalog for the app group.
```

## The wire contract

`BuzzActivityAttributes.ContentState` must match `ActivityState` in the Worker
(`apps/ping/src/api/sessions/types.ts`) field for field. The server pushes it into whatever build is
on the phone, and people do not update apps promptly, so **the server is always talking to clients
older than itself.**

- `version` carries `ACTIVITY_SCHEMA_VERSION`. Adding an optional field is safe and needs no bump.
  Renaming, removing or repurposing one does — and the server must keep the old field populated
  until the old builds are gone.
- **`status` is a `String`, never an enum.** A new status on the server must not break decoding on an
  old build; `BuzzStatus.init` maps anything unknown to `working`.
- The widget must render something sane for a `version` *higher* than it knows, because that is the
  normal case for a few days after every server deploy.

## Rules

- **Buzz never talks to `api.buzzkit.dev` directly except through the BuzzKit SDK.** Everything else
  goes to `ping.buzzkit.dev` through `PingClient`. Two hosts, two jobs.
- **The buzzkit identity is handed over exactly once, at pair time**, and lives in the app group. The
  ping key is a bearer URL that people paste into agent configs; it must never be able to fetch the
  identity back. Losing the identity means re-pairing, and that is the intended recovery.
- **`Shared/` is compiled into both targets, so it may not import BuzzKit.** The widget extension
  does not link the SDK. Keep SDK use inside `Buzz/`.
- **Swift 6 strict concurrency is on.** `Activity` is not `Sendable`: wrap it in `Unchecked` before
  it crosses into a `Task`, the way the BuzzKit SDK does. Static `let`, never `var`.
- **Design iteration goes through the preview, not through pushes.** `ActivityPreviewView` renders
  every state from `BuzzSamples`; reach it with the debug launch argument rather than by pairing.

## Design

The app is the buzzkit design system (`docs/design.md` in the monorepo) on a phone: the same
tokens, type, shape, motion and copy rules as the dashboard and buzzkit.dev, so every surface reads
as one product.

- **Tokens only.** Every color comes from `Theme` (`Shared/UI/Theme/Theme.swift`), the neutral
  ladders `bg1`…`bg4` / `fg1`…`fg4` plus the status ramps, converted from the OKLCH values in
  `packages/ui/src/styles/globals.css` for both appearances. Never a literal color in a view, never
  `.primary`/`.secondary`/`.accentColor`. `fg1` is decorative only, never text. The brand violet
  (`brand1`, `brand2`) tints the onboarding wash and nothing else; the primary action is black
  (`primary` = `fg4`). Status colors mean status: sky working, amber waiting, green done, red
  failed, read through `BuzzStatus.tint`.
- **Open Runde for everything except code.** `.typo(FontSize.sm, weight: .medium)` sets the face,
  the size and the `-0.02em` tracking (`Font.typo` when a `Font` is needed); `.medium` is the UI
  weight and hierarchy comes from the `fg` ramp and size, not from weight. Sizes come from
  `FontSize` (xs 13, sm 14, base 16, xl 20, xxl 24, hero 34). Snippets and the endpoint are the
  one monospace exception (`Font.mono`). Never `.system`, never `.bold`.
- **Icons are Central Icons.** `Icon("IconName")` renders a template SVG from
  `Shared/Resources/Icons.xcassets`; add one by rendering it from `@central-icons-react/all` the
  way `packages/ui/scripts/generate-icons.ts` does (`radius: '3'`, `stroke: '2'`, `join: 'round'`,
  `fill: 'filled'` for the `Filled` suffix). No SF Symbols anywhere the app draws itself; system
  surfaces (confirmation dialogs, menus) keep the system's own glyphs.
- **Shape.** Continuous corners at `Theme.Radius`: 12 controls and code blocks, 16 cards, 22
  notification cards, 24 sheets. Cards carry a hairline ring and a soft shadow (`Card`), never a
  border; dividers are `Hairline` in `bg3`.
- **Mobile buttons use AppButton.** Primary actions use md (50pt) or lg (54pt), full width,
  with flat capsule surfaces, 20pt md / 22pt lg labels and press feedback. All variants keep at least 44pt touch
  targets. Variants are primary, secondary, ghost and destructive. Pairing actions sit at the
  bottom; the content scrolls when larger text needs more room.
- **Endpoint dialogs use customSheet**, ported from CruiseSignal with BezelKit corners and
  fit-content height. Inject observable models explicitly and dismiss through sheetDismiss.
- **Motion.** `Motion`: 150ms ease-out for presses, the 0.3s bounce-0 spring for state swaps,
  and the icon-swap recipe (`iconSwap(shown:)`: 0.65 scale, 2px blur, one symmetric cross-fade) for
  any glyph that replaces another. Screens render settled; the onboarding stack is the one
  entrance, and it stands still under Reduce Motion.
- **Every view has a `#Preview`** with self-contained sample data (`BuzzSamples`,
  `SampleNotification.pool`, `PairingModel.pairedPreview` / `.unpairedPreview`), never a network
  call. `@State` is private, injected observables come through `@Environment(PairingModel.self)`,
  every tappable thing is a `Button`, and every icon-only control carries an accessibility label.
- **Copy.** Sentence case, full sentences, one job per string, no em or en dashes, buttons start
  with a verb, destructive confirms repeat their consequence ("Rotate endpoint", never "Confirm").

## The stage is a notification center

The stage always mounts the timeline (`TimelineFeed`) once paired, with the sample stack layered
over it only while there is nothing to show; the first real event therefore animates in exactly
like every later one while the samples fade out, instead of the whole stage swapping. The feed: the running Live Activity pinned on top, then `GET /:key/timeline` newest first
as `TimelineCard`s built on `PushCard` (the same card the sample stack uses). Agent connected,
notifications and session status changes (a `waiting` status among them) all appear with a relative
time (`TimelineClock`).
A session is never shown twice. While the pinned Live Activity is carrying a session, that session's
current-status card is filtered out of the feed (`visibleEvents` hides an event whose `session` and
`status` match a session in the activity). Only its *past* steps stay in the list (a working card
after it has gone waiting), and its current card appears the moment the activity ends or the session
leaves it (finished sessions linger 90s first). Plain notifications, which carry no session, always
show.
`PushCard` copies Notification Center exactly (measured against real screenshots, 2026-09-07): the
38pt icon is centred on the whole text block, the title is one 15pt semibold line with tail truncation that keeps clear of the
timestamp, the timestamp is pinned top-right on the first line even when the title stands alone,
the app icon gives way to the agent's avatar (`Shared/Resources/Agents.xcassets`,
`AgentLabel.avatar(for:)`) when the event names a known agent, the body is 15pt regular up to four lines with tail truncation and honours hard newlines. 15pt is
the one size outside `FontSize`, on purpose: it is what iOS uses. The only outcome footer is a
finished session with "Finished after 4m 12s" from `durationMs`; a failed or waiting session gets no
footer, its status dot already says it and there is nothing to add. The footer lives in a `CardFooter`
hairline sub-row under the body, never inside the notification; the footer band is painted by the
card background itself (a bg2 strip the height of the footer under the bg1 fill, clipped once), never
as the footer view's own background: a child background gets re-rounded on device and shows the
card's white corners beneath it. Every card is long-pressable for a single Copy item (title and body);
SwiftUI attaches no long-press to an empty `contextMenu`, so the Copy item is what keeps the gesture.
Cards carry no buttons and no reply — Buzz reports, and the decision happens at the desk. No custom
`preview:`, the lifted card is the card itself; a custom preview re-laid the text and wrapped it
differently. No "Time sensitive" eyebrow, that is iOS chrome, not content. `TimelineModel` is pushed,
not polled: while the feed is visible it holds a WebSocket to `/:key/stream` (`listen()`, reconnecting
with backoff) and refetches on every `timeline` message; it also refetches on launch, on foreground,
on each activity change, on pull-to-refresh, and every 15s as a safety net. A new top
event scrolls the feed to a 16pt spacer view at the very top of the content (not to the card), so
the padding above the first card is visible after the scroll; the vertical inset is that spacer,
not `contentMargins`, because `scrollTo` ignores margins. `-BuzzPreviewTimeline` (with
`-BuzzPreviewHome`) loads sample events; the preview menu toggles them. The view is named
`TimelineFeed` because SwiftUI already owns `TimelineView`.

The pairing section always sits under the stage, connected or not; the timeline just takes over
the stage; its title animates from "Connect an agent" to "Connect another agent" through
`numericText` once the timeline has ever had an event (`TimelineModel.hasConnected`, persisted,
so "Clear notifications" in the `…` menu, which empties the server timeline after a system alert,
does not flip it back). A full-screen mode (the section sliding away, the stage growing edge to edge, a close
button to bring it back) was built and dropped on 2026-09-07: the width change re-broke lines mid
animation and the header never sat well over the wash. Do not reintroduce it.

Haptics: one light impact on press-down from `PressButtonStyle`, nothing on release and no extra
success tap on copy. Two haptics per tap feels like a double fire.

## Agent avatars are communication notifications

Every push that names an agent (`data.agent`) is turned into a communication notification by the service extension: it donates an
`INSendMessageIntent` whose sender is the agent (display name from `AgentLabel`, avatar from
`Agents.xcassets`) and applies it with `content.updating(from:)`, so iOS shows the agent's avatar
where the app icon would be, like a WhatsApp sender. The original title moves to the subtitle
because iOS takes the sender's name as the title. Needs
`com.apple.developer.usernotifications.communication` on the app (registered on the App ID from
Xcode's Signing & Capabilities once; not on the extension, whose App ID refused it) and
`NSUserActivityTypes: [INSendMessageIntent]`. `AgentLabel` knows ~35 ids (Claude, Codex/OpenAI/ChatGPT, Cursor, Copilot, Gemini/Jules,
Windsurf, Zed, Replit, Warp, v0, Junie, Mistral, DeepSeek, Grok, Cline/Roo/Kilo, OpenCode, Qwen,
Perplexity, Hugging Face, Ollama, Amp, Trae); anything else gets a generated monogram avatar (first
letter on one of six colours picked by an FNV hash of the name; never `hashValue`, which is
randomised per process and would give the extension and the app different colours), so every agent has a face. `PushCard` takes the agent
id, not an asset name, and asks `AgentLabel.image(for:)`.

**A ping can carry a custom `avatar` URL** for a bot with no bundled logo, and it wins over the
monogram. `AvatarStore` (Shared) is the whole mechanism: an app-group cache keyed by the SHA-256 of
the URL, `image(for:)` a synchronous disk read and `warm(_:)` a downscale-to-256 fetch (https only,
2 MB cap). It is shaped by where each surface can run: a **Live Activity cannot fetch at render**, so
the widget's `AgentAvatar` only ever reads the cache, and the app fills it — `TimelineFeed` warms
every avatar URL it sees (its own `.task`) and `PushCard` warms as it renders. The in-app card shows
the custom avatar immediately through `AsyncImage`; the notification-service extension resolves it
from the cache synchronously (and kicks a detached `warm` for next time, since it cannot call `super`
inside a `Task` under Swift 6 strict concurrency), so a brand-new avatar shows the bundled/monogram
fallback on its very first push and the real icon after. Custom avatars are drawn as-is with no tile,
so they must be square and opaque like an app icon; the bundled marks carry their own tile. The avatars copy each product's real app icon: the official mark from `@lobehub/icons-static-svg`
(https://github.com/lobehub/lobe-icons; Zed and Warp from Simple Icons, which lacks OpenAI, Codex
and Grok) on the tile that product actually ships, 256px, radius 58, glyph 150px, rendered once
with rsvg-convert. White mark on the brand tile where that is the icon (Claude terracotta, Cursor,
Grok, ChatGPT and v0 black, Replit orange, Windsurf teal), the coloured mark on a light tile where
the real icon is light (Codex, Gemini, DeepSeek, Qwen, Ollama), and the coloured mark on a dark tile
for the rest (Mistral, Perplexity, Junie, Trae, Amp). `AgentAvatar` adds a 0.5pt 8% ring so the
light tiles still read on a light card. Codex, ChatGPT and Grok each have their own mark; never the
OpenAI flower for Codex or the X mark for Grok. iOS re-renders a Live Activity and a delivered
notification only on their next update, so an avatar swap shows on old ones only after new content
arrives.

## The Live Activity

`LockScreenView` (Shared, so the app can preview it) has two shapes, no buttons — it reports, it
never asks for a tap. One session is a header: `ActivityHeader` (36pt `AgentAvatar` of the lead
agent with its status dot, 15pt semibold headline, 13pt detail at 55%, two lines on the Lock Screen
and one in the island, `TrailingBadge` on the right: "Waiting" amber, "Done" green, "Failed" red,
"N live" sky, or the bare percentage, rolling through `numericText` so updates count up instead of
snapping) with a 4pt `ProgressBar` under it. Several agents show `SessionRows`, a clean list with no
header (a header plus a list repeated the lead agent twice, which read as duplication): each row a
full mini header (28pt avatar with dot, 15pt title, one line of body or project, percentage or status
glyph on the right), hairlines inset to the text, "and N more" last. A waiting agent is just a row or
a header with the amber dot and badge; there is nothing to tap. iOS caps the Lock Screen presentation at 160pt
and squeezes padding past it, so the list shows three rows at most, and two rows plus "and N more"
when there are more than three; with exactly two agents the rows relax to 36pt avatars and 12pt
padding since there is room. The expanded island (`island: true`) is tighter still: 32pt avatars
and 8pt padding for two rows, 28pt and 5pt once there are three rows or an "and N more" line,
because its height cap is lower than the Lock Screen's and the roomy rows clip at the bottom. Nothing in a Live Activity animates on its own (the system renders
snapshots), so status glyphs stay static by design.
A header plus a list repeated the lead agent twice, which read as duplication.
The Dynamic Island reuses the same pieces: expanded shows `SessionRows` alone in `.bottom` for
several agents, otherwise the whole `ActivityHeader` in the `.center` region (never split across `.leading`/`.trailing`, they top-align against a taller
centre) and the `ProgressBar` in `.bottom` with its own vertical padding (the region clips a
bare 4pt bar), compact
is the lead avatar and a percentage / status glyph, minimal is the avatar with its dot. Every
agent shows as its avatar, which is why the widget target compiles `Shared/` including
`Agents.xcassets` and `AgentLabel`. Verify the Lock Screen through `-BuzzPreviewActivity`; the
island only on a device.

**The app reconciles the activity against the server whenever it is open.** APNs throttles Live
Activity pushes, and after a day of start/end cycles a done update or the end push simply never
lands, leaving the phone reading "1 agent working" over two finished rows. So `ActivityMonitor.reconcile()`
(on launch, every 15s with the timeline poll, and after every timeline change) fetches `GET /:key`
and makes the local activity match: it updates the content when it differs (ignoring `updatedAt`),
ends it when the server has no sessions or has bound a different id, and starts one itself when the
server has sessions but no activity, which the binder then reports back like any other start. The
`-BuzzStartLocalActivity` flag is the same idea by hand and is only needed when the server has no
sessions to start from.

## Pairing a computer

The phone never hands its URL over by hand. Home shows a six-digit code (`POST /:key/code`, five
minutes, single use) and the sentence to say to an agent, "Set up Buzz with code 482913"; the agent
claims it with `POST /pair/claim` and gets the endpoint and the MCP URL back (the public `skill.md`
documents this). The code refreshes itself when it expires. A code is only a
short-lived pointer to the current key: claiming returns the key itself, so agents store the
endpoint, not the code. Rotating mints a new key and revokes the old one, which disconnects every
agent at once; each needs a fresh code. Copy about rotate must say that. The raw endpoint and rotate live in the
`…` menu, one step away, because they are the exception, not the setup.

Debug launch arguments: `-BuzzPreviewUnpaired`, `-BuzzPreviewHome` (a sample endpoint and code),
`-BuzzPreviewLive` (with `-BuzzPreviewHome`: the stage shows a sample activity), `-BuzzPreviewEndpoint`
(with `-BuzzPreviewHome`: opens the endpoint sheet), `-BuzzPreviewConnecting` (with
`-BuzzPreviewHome`: no code yet, the CTA spins), `-BuzzPreviewNotificationsOff` (with
`-BuzzPreviewHome`: the muted stage), `-BuzzPreviewOffline` and `-BuzzPreviewError` (the
connection states), `-BuzzPreviewActivity` and
`-BuzzStartPreviewActivity` (starts the waiting sample as a real activity). `xcrun simctl io screenshot` does not capture Dynamic Island content on
the simulator, it draws an empty outline whatever the widget renders, so verify the island on a
device and the Lock Screen view through the preview.

## Commands

| Command | Description |
|---|---|
| `xcodebuild -project Buzz.xcodeproj -scheme Buzz -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGN_IDENTITY=- build` | Build |
| `xcodebuild -project Buzz.xcodeproj -scheme Buzz -destination 'platform=iOS,id=<udid>' -configuration Debug -allowProvisioningUpdates -derivedDataPath build-device build && xcrun devicectl device install app --device <udid> build-device/Build/Products/Debug-iphoneos/Buzz.app && xcrun devicectl device process launch --device <udid> studio.overclock.buzz` | Run on Christo's iPhone (`xcrun devicectl list devices` for the udid) |

Prefix with `DEVELOPER_DIR=/Applications/Xcode-27.app` when `xcrun` resolves to CommandLineTools.

`Buzz.xcodeproj` is the source of truth and is committed: add files through Xcode (or edit
`project.pbxproj` when working from the shell, and confirm the file appears in the target), and
keep the team (`5DL44U5BHU`, automatic signing) set on every target. BuzzKit is the remote
package `https://github.com/buzzkit-dev/buzzkit-ios.git` on `main` (Xcode Cloud cannot see a
sibling directory); to develop against a local checkout, drag `../BuzzKit-iOS` into the project
and Xcode overrides the remote with it (same package identity, `buzzkit-ios`), and drop it again
before committing. The version and build number live once, at the project level
(`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION` in the Buzz project's Build Settings); every
Info.plist reads them through `$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)`, so the app
and both extensions always agree. Bump them on the project, never on one target, or App Store
Connect rejects the upload for an extension version that does not match the app.

Releases are Xcode Cloud archives built with the current release Xcode (the 27 betas cannot
submit). `ci_scripts/ci_post_clone.sh` (the CruiseSignal script) sets `MARKETING_VERSION` from
the `vX.Y.Z` tag that triggered the build, or from the highest tag on a branch build, and Xcode
Cloud supplies the build number. Cut a release by pushing a tag; the number in the project is
only a local default.

Loading states use `Spinner` (the CruiseSignal ring: 30% track plus a quarter arc, 900ms per
turn), never `ProgressView`. Inside `AppButton` the spinner takes the exact size of the icon slot
it replaces, so "Connecting…" and the clipboard icon read as the same weight.

Anything that stops Buzz from reaching you renders inside the stage, never as a card below it:
`Stage(muted:)` drops the brand wash and `StageNotice` greys and blurs the sample cards behind a
badge, a title, one sentence and the action (`StageNotice.notificationsOff()` with Open Settings,
`StageNotice.connection(issue, …)` with Try Again / Reconnect from `ConnectionIssue`). The stage is optimistic: a connection issue only takes the stage over when there is nothing
else to show (no cached events, no running activity); otherwise the timeline stays and the issue
lives in the status pill ("Offline" / "Not connected", amber). While an issue is showing, the code
tiles stay empty and the copy button is disabled. An issue is only
surfaced after four failed attempts two seconds apart (`PairingModel.attempts`), because Tailscale
on the phone takes a few seconds to come back after launch; once surfaced, a recovery task keeps
trying every five seconds and clears the notice by itself; meanwhile the feed shows the
last events from its UserDefaults cache. The preview menu can force the offline and error states.

Sign simulator builds ad hoc (`CODE_SIGN_IDENTITY=-`), never `CODE_SIGNING_ALLOWED=NO`: an unsigned
build carries no entitlements, so `aps-environment` is missing, APNs registration fails with
"no valid aps-environment entitlement", and no push ever reaches the simulator.

Simulators need `widgets` and `store` left enabled, or Live Activities and push both go silent:

```
simslim on <udid> --except widgets,store
```

Screenshot every activity state without a server:

```
xcrun simctl launch <udid> studio.overclock.buzz -BuzzPreviewActivity
```

Pairing screen hierarchy: 16pt status, supporting text, and actions; 24pt heading; 28pt code.
Header status and menu both use 44pt surfaces. Use 24pt section gaps (27pt between the code tiles and the CTA, because the
description text above the tiles carries about 2pt of its own leading and the two gaps should look
equal) and **2pt between a title and
its description**, everywhere (page heading, sheet heading, stage notice); 4pt and up read too loose. Hide the expiry countdown; codes still refresh automatically. The screen never scrolls: the stage takes whatever height is left
(min 160pt) and shows one sample notification instead of two below 340pt, so small phones fit
without a scroll view. Dynamic Type is capped at xLarge on this screen for the same reason. Do not
insert an expanding spacer between the artwork and the pairing section. No gloss or raised shadows on controls.

The copy action uses title case (Copy Setup Message / Copied Setup Message), numericText content
transitions, and simultaneous icon scale (0.75), opacity and 2pt blur transitions. Code digit
slots retain stable identity and use numericText during automatic refresh. The copied message
links to the public skill instructions so a new agent knows how to claim the code and set up Buzz.

Startup opens Connect an agent immediately, restoring the existing endpoint or creating one in
place. Pairing failures show a retry inline. The Get started onboarding screen has been removed.
Main CTA uses CruiseSignal lg: 54pt height and 22pt text (md is 50pt / 20pt).
In Debug builds on real devices, More → Preview Screens opens an isolated sample model without
network access. Its More menu offers idle, working, waiting, notifications-off and connecting
samples; Done returns to the real app. The endpoint field (`EndpointField`) is one big button: tapping
anywhere copies the full URL, the trailing clipboard swaps to a green checkmark with the button's own
scale/fade/blur transition, and the URL shows without its scheme, host (plus port) in fg2 and the
`/key` path in fg4, Open Runde (never mono) at 16pt, tail-truncated, in a full capsule that does not
scale on press. Sheet title and description use the same sizes as the stage notice (xl medium, base). Rotate
confirms through a system alert, not a confirmation dialog. Sample endpoints cannot rotate stored credentials. -BuzzPreviewUnpaired opens the unpaired
screen without issuing a request for UI testing.
