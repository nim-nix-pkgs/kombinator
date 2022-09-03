# Package

version       = "1.3.1"
author        = "Arnaud Moura"
description   = "Kombinator is a tool to generate commands line from parameters combination from a config file."
license       = "MIT"
srcDir        = "src"
bin           = @["kombinator"]
binDir        = "bin"
backend       = "c"


# Dependencies

requires "nim >= 1.4.2"
requires "parsetoml >= 0.5.0"
requires "cligen >= 1.2.2"
requires "suru >= 0.3.0"

