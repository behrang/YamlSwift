struct Tag: Equatable {
  let uri: String
  let construct: (Node, (Tag, [Node], Node) throws -> Tag) throws -> Yaml
  let canonical: (String) -> String

  init (_ uri: String,
      construct: @escaping
        (Node, (Tag, [Node], Node) throws -> Tag) throws -> Yaml
          = { _, _ in throw YamlError.message("tag has no constructor") },
      canonical: @escaping (String) -> String = { $0 }) {
    self.uri = uri
    self.construct = construct
    self.canonical = canonical
  }

  func to_canonical (_ formatted: String) -> String {
    return canonical(formatted)
  }

  static func == (lhs: Tag, rhs: Tag) -> Bool {
    return lhs.uri == rhs.uri
  }
}

let tag_mapping = Tag("tag:yaml.org,2002:map", construct: { node, resolve in
      switch node {
      case .mapping(let map, _):
        var result: [Yaml: Yaml] = [:]
        try map.forEach {
          let key = try $0.0.construct(resolve)
          let value = try $0.1.construct(resolve)
          result[key] = value
        }
        return .dictionary(result)
      default: throw YamlError.message("expected mapping node")
      }
    })

let tag_sequence = Tag("tag:yaml.org,2002:seq", construct: { node, resolve in
      switch node {
        case .sequence(let seq, _):
          return .array( try seq.map { try $0.construct(resolve) } )
        default: throw YamlError.message("expected sequence node")
      }
    })

let tag_string = Tag("tag:yaml.org,2002:str", construct: { node, _ in
      switch node {
      case .scalar(let content, _):
        return .string(content)
      default: throw YamlError.message("expected scalar node")
      }
    })

let tag_null = Tag("tag:yaml.org,2002:null", construct: { node, _ in
      switch node {
      case .scalar:
        return .null
      default: throw YamlError.message("expected scalar node")
      }
    }, canonical: { _ in "null" })

let tag_bool = Tag("tag:yaml.org,2002:bool", construct: { node, _ in
      switch node {
      case .scalar(let content, _):
        let c = content.lowercased()
        if match(c, "^(true|on|yes)$") {
          return .bool(true)
        } else if match(c, "^(false|off|no)$") {
          return .bool(false)
        } else {
          throw YamlError.message("invalid bool literal: \(content)")
        }
      default: throw YamlError.message("expected scalar node")
      }
    }, canonical: {
      if match($0.lowercased(), "^(true|on|yes)$") {
        return "true"
      } else {
        return "false"
      }
    })

let tag_int = Tag("tag:yaml.org,2002:int", construct: { node, _ in
      switch node {
      case .scalar(let content, _):
        var c = content.lowercased()
        var radix = 10
        if match(c, "^0o") {
          radix = 8
          c = content.substring(from: content.index(content.startIndex, offsetBy: 2))
        } else if match(c, "^0x") {
          radix = 16
          c = content.substring(from: content.index(content.startIndex, offsetBy: 2))
        }
        if let i = Int(c, radix: radix) {
          return .int(i)
        } else {
          throw YamlError.message("invalid integer literal: \(content)")
        }
      default: throw YamlError.message("expected scalar node")
      }
    }, canonical: {
      var c = $0.lowercased()
      var radix = 10
      if match($0, "^0o") {
        radix = 8
        c = $0.substring(from: $0.index($0.startIndex, offsetBy: 2))
      } else if match($0.lowercased(), "^0x") {
        radix = 16
        c = $0.substring(from: $0.index($0.startIndex, offsetBy: 2))
      }
      if let i = Int(c, radix: radix) {
        return i.description
      } else {
        return "0"
      }
    })

let tag_float = Tag("tag:yaml.org,2002:float", construct: { node, _ in
      switch node {
      case .scalar(let content, _):
        let c = content.lowercased()
        if match(c, "^\\+?\\.inf$") {
          return .double(Double.infinity)
        } else if match(c, "^-\\.inf$") {
          return .double(-Double.infinity)
        } else if match(c, "^\\.nan$") {
          return .double(Double.nan)
        } else if let f = Double(content) {
          return .double(f)
        } else {
          throw YamlError.message("invalid float literal: \(content)")
        }
      default: throw YamlError.message("expected scalar node")
      }
    }, canonical: {
      let text = $0.lowercased()
      if match(text, "^(\\.inf|-\\.inf|\\.nan)$") {
        return text
      }
      if let f = Double($0) {
        return f.description // todo: format using scientific notation
      } else {
        return "0"
      }
    })

let tag_non_specific = Tag("!")
let tag_unknown = Tag("?")
