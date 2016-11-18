enum Node {
  case scalar(String, Tag)
  case sequence([Node], Tag)
  case mapping([Node: Node], Tag)
  case alias(Box)

  var tag: Tag {
    switch self {
    case .scalar(_, let tag): return tag
    case .sequence(_, let tag): return tag
    case .mapping(_, let tag): return tag
    case .alias: fatalError("alias nodes don't have tags")
    }
  }

  var content: String {
    switch self {
    case .scalar(let c, _): return c
    default: fatalError("non-scalar nodes don't have content")
    }
  }

  func construct (_ resolve: (Tag, [Node], Node) throws -> Tag) throws -> Yaml {
    switch self {
    case let .scalar(_, t):
      let tag = try resolve(t, [], self)
      let value = try tag.construct(self, resolve)
      return value
    case let .sequence(_, t):
      let tag = try resolve(t, [], self)
      let value = try tag.construct(self, resolve)
      return value
    case let .mapping(_, t):
      let tag = try resolve(t, [], self)
      let value = try tag.construct(self, resolve)
      return value
    case let .alias(box):
      guard let node = box.node else {
        throw YamlError.message("unidentified alias: \(box.anchor)")
      }
      if let value = box.yaml {
        return value
      } else {
        let value = try node.construct(resolve)
        box.yaml = value
        return value
      }
    }
  }
}

extension Node: CustomDebugStringConvertible {
  var debugDescription: String {
    switch self {
    case let .scalar(content, tag): return ".scalar(\(content), \(tag.uri))"
    case let .sequence(seq, tag): return ".sequence(\(seq), \(tag.uri))"
    case let .mapping(map, tag): return ".mapping(\(map), \(tag.uri))"
    case let .alias(box): return ".alias(\(box.anchor))"
    }
  }
}

extension Node: Hashable {
  var hashValue: Int {
    return String(describing: self).hashValue
  }
}

extension Node: Equatable {
  static func == (lhs: Node, rhs: Node) -> Bool {
    switch (lhs, rhs) {
    case let (.scalar(c1, t1), .scalar(c2, t2)):
      return t1 == t2 && t1.to_canonical(c1) == t2.to_canonical(c2)
    case let (.sequence(s1, t1), .sequence(s2, t2)):
      return t1 == t2 && s1 == s2
    case let (.mapping(m1, t1), .mapping(m2, t2)):
      return t1 == t2 && m1 == m2
    case let (.alias(b1), .alias(b2)):
      return b1 === b2
    case let (.alias(box), node):
      return box.node == node
    case let (node, .alias(box)):
      return box.node == node
    default: return false
    }
  }
}

typealias AnchorMap = [String: Box]

class Box {
  let anchor: String
  var node: Node?
  var yaml: Yaml?

  init (_ anchor: String) {
    self.anchor = anchor
  }
}
