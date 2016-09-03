import Parsec

typealias YamlParser<a> = StringUserParser<a, YamlState>
typealias YamlParserClosure<a> = StringUserParserClosure<a, YamlState>

struct YamlState {
}
