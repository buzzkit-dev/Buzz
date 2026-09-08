<!-- Header -->
<div align="center">
  <a href="https://buzzkit.dev/buzz">
    <img src="https://buzzkit.dev/buzz/icon.png" alt="Buzz" height="96" />
  </a>

  <h3 align="center">Buzz</h3>
  <b>What your coding agents are doing, on your Lock Screen</b>
</div>

<!-- TOC -->
<p align="center">
    <a href="https://buzzkit.dev/buzz"><strong>Learn more »</strong></a>
    <br />
    <br />
    <a href="#introduction">Introduction</a>
    ·
    <a href="#the-endpoint">The Endpoint</a>
    ·
    <a href="#how-it-fits-together">How It Fits Together</a>
    ·
    <a href="#building">Building</a>
</p>

## Introduction

Buzz gives your phone one endpoint your coding agents post to. They send a notification when work finishes, keep a Live Activity on your Lock Screen while it runs, and flag when they are blocked and need you. Several agents running at once merge into one live view, sorted by whichever one needs you first.

Buzz reports; it never acts for you. When an agent is blocked it shows "Waiting on you" and you make the call where you always have, in your editor. There is no account and nothing to install on the machine running the agent: it reads one setup guide, claims a six-digit code, and starts posting.

Buzz is a product built on [BuzzKit](https://buzzkit.dev), the open source notification framework, on the same public SDK anyone else would use. Get it at [buzzkit.dev/buzz](https://buzzkit.dev/buzz).

## The Endpoint

Everything is one `POST`. A finished piece of work is a notification:

```sh
curl -X POST https://ping.buzzkit.dev/YOUR_KEY \
  -d '{"title":"Tests passed","body":"142 passed in 38s","agent":"claude-code"}'
```

Add a stable `session` and the same call drives a Live Activity instead, updating in place as the work moves:

```sh
curl -X POST https://ping.buzzkit.dev/YOUR_KEY \
  -d '{"session":"api/migrate","title":"Running migrations","progress":0.4,"status":"working"}'
```

Set `status` to `waiting` when you are blocked, and it floats to the top of the Lock Screen as "Waiting on you". The full agent guide lives at [`ping.buzzkit.dev/skill.md`](https://ping.buzzkit.dev/skill.md).

## How It Fits Together

| Piece | Where |
| --- | --- |
| The app | this repository |
| The API | `apps/ping` in the [buzzkit](https://github.com/buzzkit-dev/buzzkit) monorepo, at `ping.buzzkit.dev` |
| The product page | [buzzkit.dev/buzz](https://buzzkit.dev/buzz) |
| The agent setup guide | [`ping.buzzkit.dev/skill.md`](https://ping.buzzkit.dev/skill.md) |

The app pairs with the API once and stores its credentials in the Keychain. From then on the API derives one merged Live Activity from every agent's session and pushes it; the app reports back the activity id and its push tokens, and mirrors the running activity into its own timeline.

## Building

Requires Xcode 27 and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
xcodegen generate
open Buzz.xcodeproj
```

`Buzz.xcodeproj` is generated from `project.yml`, so it is not checked in — edit targets, entitlements and build settings in `project.yml` and regenerate. Run `xcodegen generate` again whenever files are added.

```
Buzz/                     The app: pairing, the timeline, the connect screen
Shared/                   Compiled into both the app and the widget
├── Activity/             The Live Activity wire contract and its sample states
├── Networking/           The ping client, app-group storage, agent avatars
└── UI/                   Theme tokens, the Lock Screen views, shared components
BuzzWidget/               The Live Activity and Dynamic Island
BuzzNotificationService/  Turns each push into a communication notification (the agent's avatar)
```

## License

Buzz is part of [BuzzKit](https://github.com/buzzkit-dev/buzzkit), licensed under the [GNU Affero General Public License Version 3 (AGPLv3)](https://github.com/buzzkit-dev/buzzkit/blob/main/LICENSE).
