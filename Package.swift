// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ToDoListApp",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "ToDoListCore",
            targets: ["To_Do_List"]
        )
    ],
    targets: [
        .target(
            name: "To_Do_List",
            path: "ToDoListApp",
            exclude: [
                "AppDelegate.swift",
                "Assets.xcassets",
                "Settings",
                "Sync",
                "ToDoListApp.entitlements",
                "ToDoListApp.swift",
                "Views"
            ],
            sources: [
                "Models",
                "Storage"
            ]
        ),
        .testTarget(
            name: "ToDoListAppTests",
            dependencies: ["To_Do_List"],
            path: "ToDoListAppTests"
        )
    ]
)
