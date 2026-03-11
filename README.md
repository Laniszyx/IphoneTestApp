# IphoneTestApp — Compass App

A SwiftUI Compass app for iPhone that points toward any pinned location on the map.

## Features

| Feature | Details |
|---|---|
| 🧭 Live Compass | Animated compass rose that rotates with device heading |
| 📍 Target Needle | Blue arrow always points toward your pinned destination |
| 🗺 Map View | Full MapKit map for selecting a target |
| 🔍 Search | Search for any city, country, or address by name |
| 📌 Long-press Pin | Long-press anywhere on the map to drop a pin |
| 📏 Distance | Shows distance to target (m / km) |
| 🧲 Bearing | Shows bearing in degrees and cardinal direction |
| 📱 iOS 16+ | Targets iPhone, requires magnetometer |

## Project structure

```
CompassApp/
├── CompassApp.xcodeproj/      # Xcode project
└── CompassApp/
    ├── CompassAppApp.swift    # @main entry point
    ├── ContentView.swift      # TabView (Compass + Map tabs)
    ├── CompassView.swift      # Compass rose, North needle, target needle
    ├── MapTargetView.swift    # MapKit map with search + pin
    ├── LocationManager.swift  # CLLocation + CLHeading updates
    ├── BearingCalculator.swift # Great-circle bearing math
    ├── Assets.xcassets/       # App icon, accent colour
    └── Info.plist             # Location permissions
```

## How to build and install on your iPhone

### Prerequisites
- macOS with **Xcode 15** or later
- An Apple Developer account (free tier works for personal device sideloading)
- iPhone running **iOS 16** or later with [Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device) enabled

### Steps

1. **Clone the repo on your Mac**
   ```bash
   git clone https://github.com/Laniszyx/IphoneTestApp.git
   cd IphoneTestApp
   ```

2. **Open the Xcode project**
   ```bash
   open CompassApp/CompassApp.xcodeproj
   ```

3. **Set your signing team**
   - Select the `CompassApp` target → *Signing & Capabilities*
   - Choose your Apple ID under *Team*
   - Xcode will automatically manage provisioning profiles

4. **Connect your iPhone** via USB (or use wireless pairing)

5. **Select your device** in the scheme picker (top-left toolbar)

6. **Build & Run** — press ▶ or `⌘R`
   - Xcode builds the app and installs it directly on your device
   - On first launch, go to *Settings → Privacy & Security → Location Services* and allow location access for **Compass App**

### Build a distributable `.ipa` (optional)

For an `.ipa` you can share or install via AltStore / Sideloadly:

1. *Product → Archive* in Xcode (device must be selected, not a simulator)
2. When the Organizer opens, click *Distribute App → Direct Distribution → Export*
3. The exported `.ipa` can be installed with [AltStore](https://altstore.io/) or [Sideloadly](https://sideloadly.io/)

## Usage

| Tab | What to do |
|---|---|
| **Map** | Search for a city/country using the search bar, or long-press anywhere on the map to pin a target |
| **Compass** | The red/white needle points North; the **blue arrow** points toward your pinned target |

> **Note:** The compass requires a physical device — the iOS Simulator does not provide magnetometer data.
