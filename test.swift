import Yaml

assert(Yaml.load("") == .Null, "empty input should be null")
assert(Yaml.load("null") == .Null, "null should be null")
assert(Yaml.load("Null") == .Null, "Null should be null")
assert(Yaml.load("NULL") == .Null, "NULL should be null")
assert(Yaml.load("~") == .Null, "~ should be null")

assert(Yaml.load("NuLL") != .Null, "NuLL should NOT be null")

assert(Yaml.load("# comment line") == .Null, "A comment input should be null")

println("Done.")
