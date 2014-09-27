import Foundation

public enum Yaml {

  case YamlNull

  public static func load (text: String) -> Yaml? {
    if let range = text.rangeOfString("^(null|Null|NULL|~|$)", options: .RegularExpressionSearch) {
      return YamlNull
    } else {
      return nil
    }
  }
}
