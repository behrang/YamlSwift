public struct Schema {
  var handles = [
    "!": "!",
    "!!": "tag:yaml.org,2002:",
  ]
  var anchors: AnchorMap = [:]
  let tags: [String: Tag]
  let resolve: (Tag, [Node], Node) throws -> Tag

  init (tags: [String: Tag], resolve: @escaping (Tag, [Node], Node) throws -> Tag) {
    self.tags = tags
    self.resolve = resolve
  }
}

let failsafe_schema = Schema(tags: failsafe_tags, resolve: failsafe_resolve)
let json_schema = Schema(tags: json_tags, resolve: json_resolve)
let core_schema = Schema(tags: core_tags, resolve: core_resolve)

let failsafe_tags = [
  tag_mapping.uri: tag_mapping,
  tag_sequence.uri: tag_sequence,
  tag_string.uri: tag_string,
]

let json_tags = [
  tag_mapping.uri: tag_mapping,
  tag_sequence.uri: tag_sequence,
  tag_string.uri: tag_string,
  tag_null.uri: tag_null,
  tag_bool.uri: tag_bool,
  tag_int.uri: tag_int,
  tag_float.uri: tag_float,
]

let core_tags = [
  tag_mapping.uri: tag_mapping,
  tag_sequence.uri: tag_sequence,
  tag_string.uri: tag_string,
  tag_null.uri: tag_null,
  tag_bool.uri: tag_bool,
  tag_int.uri: tag_int,
  tag_float.uri: tag_float,
]

func failsafe_resolve (_ tag: Tag, _ path: [Node], _ node: Node) throws -> Tag {
  if tag.uri == "?" {
    return tag
  } else if tag.uri == "!" {
    switch node {
    case .sequence: return tag_sequence
    case .mapping: return tag_mapping
    case .scalar: return tag_string
    case .alias: fatalError("alias nodes don't have tags")
    }
  } else {
    return tag
  }
}

func json_resolve (_ tag: Tag, _ path: [Node], _ node: Node) throws -> Tag {
  if tag.uri == "?" {
    switch node {
    case .sequence: return tag_sequence
    case .mapping: return tag_mapping
    case .scalar(let c, _):
      if match(c, "^null$") {
        return tag_null
      } else if match(c, "^(true|false)$") {
        return tag_bool
      } else if match(c, "^-?(0|[1-9][0-9]*)$") {
        return tag_int
      } else if match(c, "^-?(0|[1-9][0-9]*)(\\.[0-9]*)?([eE][-+]?[0-9]+)?$") {
        return tag_float
      } else {
        throw YamlError.message("invalid JSON scalar: \(c)")
      }
    case .alias: fatalError("alias nodes don't have tags")
    }
  } else if tag.uri == "!" {
    switch node {
    case .sequence: return tag_sequence
    case .mapping: return tag_mapping
    case .scalar: return tag_string
    case .alias: fatalError("alias nodes don't have tags")
    }
  } else {
    return tag
  }
}

func core_resolve (_ tag: Tag, _ path: [Node], _ node: Node) throws -> Tag {
  if tag.uri == "?" {
    switch node {
    case .sequence: return tag_sequence
    case .mapping: return tag_mapping
    case .scalar(let c, _):
      if match(c, "^(null|Null|NULL|~)?$") {
        return tag_null
      } else if match(c, "^(true|True|TRUE|false|False|FALSE)$") {
        return tag_bool
      } else if match(c, "^[-+]?[0-9]+$")
          || match(c, "^0o[0-7]+$")
          || match(c, "^0x[0-9a-fA-F]+$") {
        return tag_int
      } else if match(c, "^[-+]?(\\.[0-9]+|[0-9]+(\\.[0-9]*)?)([eE][-+]?[0-9]+)?$")
          || match(c, "^[-+]?(\\.inf|\\.Inf|\\.INF)$")
          || match(c, "^(\\.nan|\\.NaN|\\.NAN)$") {
        return tag_float
      } else {
        return tag_string
      }
    case .alias: fatalError("alias nodes don't have tags")
    }
  } else if tag.uri == "!" {
    switch node {
    case .sequence: return tag_sequence
    case .mapping: return tag_mapping
    case .scalar: return tag_string
    case .alias: fatalError("alias nodes don't have tags")
    }
  } else {
    return tag
  }
}

func match (_ s: String, _ regex: String) -> Bool {
  return s.range(of: regex, options: .regularExpression) != nil
}
