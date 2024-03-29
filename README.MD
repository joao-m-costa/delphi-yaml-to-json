### YAML TOOL FOR DELPHI
A simple Delphi class to convert JSON to YAML and YAML to JSON.
Aimed for use with small YAML/JSON data.

"Pure" Delphi without any dependencies required.

Tested with Delphi 10.3 Rio.

#### YAML to JSON Capabilities
- Multiline values support, including folder modifiers (| and >), and chomp modifiers (+ and -)
- Anchor / reference support (&anchor, *anchor)
- Merge elements support (<<: *anchor)
- Tags for explicit type indicators on values only (!!map, !!seq, !!str, !!null, !!bool, !!int, !!float, !!binary, !!timestamp)
- Text escaping for JSON
- Option to translate yes/no to booleans true/false
- Option to prevent duplicated keys in maps per level

#### JSON to YAML Capabilities
- Multiline values support, including folder modifiers (| and >), and chomp modifiers (+ and -)
- Text un-escaping for YAML
- Option to translate booleans true/false to yes/no

