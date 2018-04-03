Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.name          = "Yaml"
  s.version       = "3.4.3"
  s.summary       = "Load YAML and JSON documents using Swift"
  s.description   = <<-DESC
                 YamlSwift parses a string of YAML document(s) (or a JSON document)
                 and returns a Yaml enum value representing that string.
                   DESC
  s.homepage      = "https://github.com/behrang/YamlSwift"
  s.swift_version = "4.1"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.license      = "MIT"

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.author             = { "behrang" => "behrangn@gmail.com" }

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.tvos.deployment_target = "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source       = { :git => "https://github.com/behrang/YamlSwift.git", :tag => s.version }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source_files = "Sources/Yaml/*.swift"

  # --- Target xcconfig ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '4.1',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
  }

end
