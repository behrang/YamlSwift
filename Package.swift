import PackageDescription

let package = Package(
  name: "Yaml",
  targets: [
    Target(name: "Yaml"),
  ],
  dependencies: [
    .Package(url: "https://github.com/behrang/SwiftParsec.git", majorVersion: 2)
  ]
)
