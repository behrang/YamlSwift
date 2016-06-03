import Foundation

func matchRange (_ string: String, regex: NSRegularExpression) -> NSRange {
  let sr = NSMakeRange(0, string.utf16.count)
  return regex.rangeOfFirstMatch(in: string, options: [], range: sr)
}

func matches (_ string: String, regex: NSRegularExpression) -> Bool {
  return matchRange(string, regex: regex).location != NSNotFound
}

func regex (_ pattern: String, options: String = "") -> NSRegularExpression! {
  if matches(options, regex: invalidOptionsPattern) {
    return nil
  }

  let opts = options.characters.reduce(NSRegularExpressionOptions()) { (acc, opt) -> NSRegularExpressionOptions in
    return NSRegularExpressionOptions(rawValue:acc.rawValue | (regexOptions[opt] ?? NSRegularExpressionOptions()).rawValue)
  }
  return try? NSRegularExpression(pattern: pattern, options: opts)
}

let invalidOptionsPattern =
        try! NSRegularExpression(pattern: "[^ixsm]", options: [])

let regexOptions: [Character: NSRegularExpressionOptions] = [
  "i": .caseInsensitive,
  "x": .allowCommentsAndWhitespace,
  "s": .dotMatchesLineSeparators,
  "m": .anchorsMatchLines
]

func replace (_ regex: NSRegularExpression, template: String) -> (String)
    -> String {
      return { string in
        let s = NSMutableString(string: string)
        let range = NSMakeRange(0, string.utf16.count)
        _ = regex.replaceMatches(in: s, options: [], range: range,
                                 withTemplate: template)
#if os(Linux)
        return String(s)
#else
        return s as String
#endif
      }
}

func replace (_ regex: NSRegularExpression, block: ([String]) -> String)
    -> (String) -> String {
      return { string in
        let s = NSMutableString(string: string)
        let range = NSMakeRange(0, string.utf16.count)
        var offset = 0
        regex.enumerateMatches(in: string, options: [], range: range) {
          result, _, _ in
          if let result = result {
              var captures = [String](repeating: "", count: result.numberOfRanges)
              for i in 0..<result.numberOfRanges {
                if let r = result.range(at: i).toRange() {
                  captures[i] = NSString(string: string).substring(with: NSRange(r))
                }
              }
              let replacement = block(captures)
              let offR = NSMakeRange(result.range.location + offset, result.range.length)
              offset += replacement.characters.count - result.range.length
              s.replaceCharacters(in: offR, with: replacement)
          }
        }
#if os(Linux)
        return String(s)
#else
        return s as String
#endif
      }
}

func splitLead (_ regex: NSRegularExpression) -> (String)
    -> (String, String) {
      return { string in
        let r = matchRange(string, regex: regex)
        if r.location == NSNotFound {
          return ("", string)
        } else {
          let s = NSString(string: string)
          let i = r.location + r.length
          return (s.substring(to: i), s.substring(from: i))
        }
      }
}

func splitTrail (_ regex: NSRegularExpression) -> (String)
    -> (String, String) {
      return { string in
        let r = matchRange(string, regex: regex)
        if r.location == NSNotFound {
          return (string, "")
        } else {
          let s = NSString(string: string)
          let i = r.location
          return (s.substring(to: i), s.substring(from: i))
        }
      }
}

func substringWithRange (_ range: NSRange) -> (String) -> String {
  return { string in
    return NSString(string: string).substring(with: range)
  }
}

func substringFromIndex (_ index: Int) -> (String) -> String {
  return { string in
    return NSString(string: string).substring(from: index)
  }
}
