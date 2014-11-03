import Foundation



prefix operator / {}

prefix func / (pattern: String) -> NSRegularExpression {
    return NSRegularExpression(pattern: pattern, options: nil, error: nil)!
}



infix operator / {}

func / (pattern: String, options: String) -> NSRegularExpression! {
    if options ~ /"[^ixsm]" {
        return nil
    }
    var o = NSRegularExpressionOptions()
    if options ~ /"i" {
        o |= .CaseInsensitive
    }
    if options ~ /"x" {
        o |= .AllowCommentsAndWhitespace
    }
    if options ~ /"s" {
        o |= .DotMatchesLineSeparators
    }
    if options ~ /"m" {
        o |= .AnchorsMatchLines
    }
    return NSRegularExpression(pattern: pattern, options: o, error: nil)
}



infix operator ~< { precedence 135}

func ~< (string: String, regex: NSRegularExpression) -> Range<String.Index>? {
    let srange = NSRange(location: 0, length: countElements(string))
    let range = regex.rangeOfFirstMatchInString(string, options: nil, range: srange)
    if range.location != NSNotFound && range.length != 0 {
        let start = advance(string.startIndex, range.location)
        let end = advance(start, range.length)
        return Range(start: start, end: end)
    } else {
        return nil
    }
}

func ~< (regex: NSRegularExpression, string: String) -> Range<String.Index>? {
    return string ~< regex
}



infix operator ~ { precedence 130 }

func ~ (string: String, regex: NSRegularExpression) -> Bool {
    return string ~< regex != nil
}

func ~ (regex: NSRegularExpression, string: String) -> Bool {
    return string ~ regex
}



extension String {

  func replace (regex: NSRegularExpression, _ template: String) -> String {
    var s = NSMutableString(string: self)
    let range = NSRange(location: 0, length: countElements(self))
    regex.replaceMatchesInString(s, options: nil, range: range, withTemplate: template)
    return s
  }

  func replace (regex: NSRegularExpression, _ block: [String] -> String) -> String {
    var s = NSMutableString(string: self)
    let range = NSRange(location: 0, length: countElements(self))
    var offset = 0
    regex.enumerateMatchesInString(self, options: nil, range: range) {
      result, _, _ in
      var captures = [String](count: result.numberOfRanges, repeatedValue: "")
      captures.reserveCapacity(result.numberOfRanges)
      for i in 0..<result.numberOfRanges {
        if let r = result.rangeAtIndex(i).toRange() {
          let crange = Range(
              start: advance(self.startIndex, r.startIndex),
              end: advance(self.startIndex, r.endIndex))
          captures[i] = self.substringWithRange(crange)
        }
      }
      let replacement = block(captures)
      let offsetRange = NSRange(location: result.range.location + offset, length: result.range.length)
      s.replaceCharactersInRange(offsetRange, withString: replacement)
      offset += countElements(replacement) - result.range.length
    }
    return s
  }

}
