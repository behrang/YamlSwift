enum Kind {
  case scalar
  case sequence
  case mapping
}

struct Tag: Equatable {
  let name: String
  let kind: Kind

  init (_ name: String, _ kind: Kind) {
    self.name = name
    self.kind = kind
  }

  func canonicalForm (_ input: String) -> String {
    return input
  }

  static func == (a: Tag, b: Tag) -> Bool {
    return a.name == b.name && a.kind == b.kind
  }

  static func lookup (_ pre: String) -> Tag {
    return Tag(pre, .scalar)
  }
}

let tag_non_specific = Tag("?", .scalar)
let tag_null = Tag("tag:yaml.org,2002:null", .scalar)
let tag_string = Tag("tag:yaml.org,2002:str", .scalar)
let tag_sequence = Tag("tag:yaml.org,2002:seq", .sequence)
let tag_mapping = Tag("tag:yaml.org,2002:map", .mapping)

enum Node: Hashable, Equatable {
  case scalar(String, Tag, String)
  case sequence([Node], Tag, String)
  case mapping([Node: Node], Tag, String)
  case alias(String)

  var tag: Tag {
    switch self {
    case .scalar(_, let t, _): return t
    case .sequence(_, let t, _): return t
    case .mapping(_, let t, _): return t
    case .alias: fatalError("alias nodes don't have tags")
    }
  }

  var content: String {
    switch self {
    case .scalar(let s, _, _): return s
    default: fatalError("non-scalar nodes don't have content")
    }
  }

  var hashValue: Int {
    return String(describing: self).hashValue
  }

  static func == (a: Node, b: Node) -> Bool {
    switch (a, b) {
    case let (.scalar(v1, t1, _), .scalar(v2, t2, _)):
      return t1 == t2 && t1.canonicalForm(v1) == t2.canonicalForm(v2)
    case let (.sequence(s1, t1, _), .sequence(s2, t2, _)):
      return t1 == t2 && s1 == s2
    case let (.mapping(m1, t1, _), .mapping(m2, t2, _)):
      return t1 == t2 && m1 == m2
    case let (.alias(a1), .alias(a2)):
      return a1 == a2
    default: return false
    }
  }
}
