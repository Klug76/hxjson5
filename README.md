[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.md)

# json5mod

JSON5 parser and encoder for Haxe.

This library uses some ideas from https://github.com/nadako/hxjsonast/.
It implements the JSON5 parser with some extensions from HJSON:

* Identifiers not wrapped in quotes.
* Single-quotes for strings.
* HJSON style comments.
* HJSON style multi-line strings.
* Dangling commas (commas are even optional).
* Numbers may be hexadecimal.
* Numbers may have a leading or trailing decimal point.
* The parser returns a typed object (which can be converted to Any)

# Usage

```
import gs.json5mod.Json5;
var y = Json5.parse("{}");
```
The demo folder contains an example for openfl with simple live reload support.
![demo](https://github.com/Klug76/hxjson5/blob/master/demo/demo.gif?raw=true)

# Links:

https://json5.org/

https://github.com/json5/json5

http://hjson.org/

https://github.com/hjson/

https://github.com/nadako/hxjsonast
