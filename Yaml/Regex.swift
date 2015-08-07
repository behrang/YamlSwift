import Foundation

func matchRange (string: String, regex: NSRegularExpression) -> NSRange {
  let sr = NSMakeRange(0, string.utf16.count)
  return regex.rangeOfFirstMatchInString(string, options: [], range: sr)
}

func matches (string: String, regex: NSRegularExpression) -> Bool {
  return matchRange(string, regex: regex).location != NSNotFound
}

func regex (pattern: String, options: String = "") -> NSRegularExpression! {
  if matches(options, regex: invalidOptionsPattern) {
    return nil
  }

  let opts = options.characters.reduce(NSRegularExpressionOptions()) { (acc, opt) -> NSRegularExpressionOptions in
    return NSRegularExpressionOptions(rawValue:acc.rawValue | (regexOptions[opt] ?? NSRegularExpressionOptions()).rawValue)
  }
  do {
    return try NSRegularExpression(pattern: pattern, options: opts)
  } catch _ {
    return nil
  }
}

let invalidOptionsPattern =
        try! NSRegularExpression(pattern: "[^ixsm]", options: [])

let regexOptions: [Character: NSRegularExpressionOptions] = [
  "i": .CaseInsensitive,
  "x": .AllowCommentsAndWhitespace,
  "s": .DotMatchesLineSeparators,
  "m": .AnchorsMatchLines
]

func replace (regex: NSRegularExpression, template: String) (string: String)
    -> String {
  let s = NSMutableString(string: string)
  let range = NSMakeRange(0, string.utf16.count)
  regex.replaceMatchesInString(s, options: [], range: range,
      withTemplate: template)
  return s as String
}

func replace (regex: NSRegularExpression, block: [String] -> String)
    (string: String) -> String {
  let s = NSMutableString(string: string)
  let range = NSMakeRange(0, string.utf16.count)
  var offset = 0
  regex.enumerateMatchesInString(string, options: [], range: range) {
    result, _, _ in
    if let result = result {
        var captures = [String](count: result.numberOfRanges, repeatedValue: "")
        for i in 0..<result.numberOfRanges {
          if let r = result.rangeAtIndex(i).toRange() {
            captures[i] = (string as NSString).substringWithRange(NSRange(r))
          }
        }
        let replacement = block(captures)
        let offR = NSMakeRange(result.range.location + offset, result.range.length)
        offset += replacement.characters.count - result.range.length
        s.replaceCharactersInRange(offR, withString: replacement)
    }
  }
  return s as String
}

func splitLead (regex: NSRegularExpression) (string: String)
    -> (String, String) {
  let r = matchRange(string, regex: regex)
  if r.location == NSNotFound {
    return ("", string)
  } else {
    let s = string as NSString
    let i = r.location + r.length
    return (s.substringToIndex(i), s.substringFromIndex(i))
  }
}

func splitTrail (regex: NSRegularExpression) (string: String)
    -> (String, String) {
  let r = matchRange(string, regex: regex)
  if r.location == NSNotFound {
    return (string, "")
  } else {
    let s = string as NSString
    let i = r.location
    return (s.substringToIndex(i), s.substringFromIndex(i))
  }
}

func substringWithRange (range: NSRange) (string: String) -> String {
  return (string as NSString).substringWithRange(range)
}

func substringFromIndex (index: Int) (string: String) -> String {
  return (string as NSString).substringFromIndex(index)
}

func substringToIndex (index: Int) (string: String) -> String {
  return (string as NSString).substringToIndex(index)
}
