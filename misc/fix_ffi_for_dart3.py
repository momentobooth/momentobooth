import re

# Source: https://github.com/fzyzcjy/flutter_rust_bridge/issues/1201

with open("lib/rust_bridge/library_api.generated.dart", "r+") as f:
    file = f.read()

    pattern_find = r"(:?final )?(class [a-zA-Z0-9_]+ extends (:?ffi\.Struct|ffi\.Opaque|ffi\.Union))"
    pattern_replace = r"final \2"

    file = re.sub(pattern_find, pattern_replace, file)

    f.seek(0)
    f.write(file)
    f.truncate()
