// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CelestialTides",
    platforms: [
        .macOS(.v14), .iOS(.v17)
    ],
    products: [
        .library(name: "CelestialTidesApp", targets: ["CelestialTidesApp"]),
    ],
    targets: [
        .target(
            name: "CelestialTidesApp",
            path: "CelestialTidesApp",
            exclude: [
                "Assets.xcassets",
                "CelestialTidesApp.entitlements",
                "CelestialTidesApp.swift",
                "ContentView.swift",
                "LastSelectionCell.swift",
                "LocationManager.swift",
                "SettingsSheet.swift",
                "TideChart.swift"
            ],
            sources: [
                "SharedDefaults.swift",
                "TimeZoneSelection.swift",
                "TideConfiguration.swift",
                "TideModels.swift",
                "TideCalculations.swift",
                "TideCalculations+Astronomy.swift",
                "TideCalculations+Forecast.swift",
                "TideRuntime.swift",
                "TideCalibration.swift"
            ]
        )
    ]
)
