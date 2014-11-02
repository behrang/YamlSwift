import Foundation

prefix operator / {}

prefix func / (pattern: String) -> NSRegularExpression {
    return NSRegularExpression(pattern: pattern, options: nil, error: nil)!
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
