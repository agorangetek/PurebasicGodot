#!/usr/bin/env python3
"""Generate gdextension_interface.pbi from Godot's own C header.

The PureBasic declarations have to exist - PureBasic mangles its own structures
to s_<lowercased-name> and generates field access against that, so it cannot use
the C header's types directly. What it can do is stop being HAND-WRITTEN, which
is what this does: gdextension_interface.h is the source, and every Structure
and Prototype below is derived from it.

    tools/gen_interface.py                     # regenerate in place
    tools/gen_interface.py --check             # fail if it is out of date

Type mapping, chosen to reproduce the hand transcription exactly:

    any pointer, and any function-pointer typedef   -> *field / *p_param
    uint8_t / int8_t / GDExtensionBool / char       -> .b     (1 byte)
    uint16_t / int16_t / char16_t                   -> .w     (2 bytes)
    uint32_t / int32_t / char32_t / enum            -> .l     (4 bytes)
    uint64_t / int64_t / size_t / GDExtensionInt    -> .q     (8 bytes)
    float                                           -> .f
    double                                          -> .d
    a struct used by value                          -> field.StructName

Prototypes carry NO return suffix, which is not an oversight: PureBasic's
default return is an 8-byte Integer, which is exactly right for the pointer and
GDExtensionInt returns that dominate the interface, and it is what the hand
transcription did for all 265. Narrowing the small scalar returns is a separate
change that wants per-function validation, not a generator's guess.
"""

import re
import sys
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HEADER = os.path.join(ROOT, "gdextension_interface.h")
OUTPUT = os.path.join(ROOT, "gdextension_interface.pbi")

SCALARS = {
    "void": ("", 0),
    "char": ("b", 1),
    "int8_t": ("b", 1), "uint8_t": ("b", 1),
    "int16_t": ("w", 2), "uint16_t": ("w", 2), "char16_t": ("w", 2),
    "int32_t": ("l", 4), "uint32_t": ("l", 4), "char32_t": ("l", 4),
    "int64_t": ("q", 8), "uint64_t": ("q", 8), "size_t": ("q", 8),
    "float": ("f", 4), "double": ("d", 8),
    # PureBasic-visible aliases the header uses.
    "GDExtensionBool": ("b", 1),
    "GDExtensionInt": ("q", 8),
    "GDExtensionClassFlags": ("q", 8),
}


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    text = re.sub(r"//[^\n]*", " ", text)
    return text


def parse(text):
    """Return (structs, funcptrs, aliases).

    structs  : list of (name, [(ctype, fieldname)])
    funcptrs : list of (name, rettype, [(ctype, paramname)])
    aliases  : name -> underlying C type, for typedefs that are not structs,
               function pointers or enums
    """
    text = strip_comments(text)
    # Drop preprocessor lines: only the __cplusplus guards and two includes here.
    text = "\n".join(l for l in text.splitlines() if not l.lstrip().startswith("#"))

    structs, funcptrs, aliases = [], [], {}
    i = 0
    n = len(text)

    while i < n:
        m = re.compile(r"\btypedef\b").search(text, i)
        if not m:
            break
        start = m.end()

        # Where does this typedef end? At the first ';' at brace depth 0.
        depth = 0
        j = start
        while j < n:
            c = text[j]
            if c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
            elif c == ";" and depth == 0:
                break
            j += 1
        body = text[start:j].strip()
        i = j + 1

        if body.startswith("struct") and "{" in body:
            name = re.search(r"}\s*([A-Za-z_][A-Za-z0-9_]*)\s*$", body)
            if not name:
                continue
            fields_src = body[body.index("{") + 1:body.rindex("}")]
            fields = []
            for decl in fields_src.split(";"):
                decl = decl.strip()
                if not decl:
                    continue
                fm = re.match(r"^(.*?)([A-Za-z_][A-Za-z0-9_]*)\s*$", decl, re.S)
                if not fm:
                    continue
                ctype, fname = fm.group(1).strip(), fm.group(2)
                fields.append((ctype, fname))
            structs.append((name.group(1), fields))

        elif "(" in body and "*" in body:
            fm = re.match(r"^(.*?)\(\s*\*\s*([A-Za-z_][A-Za-z0-9_]*)\s*\)\s*\((.*)\)\s*$",
                          body, re.S)
            if not fm:
                continue
            ret, name, params = fm.group(1).strip(), fm.group(2), fm.group(3)
            plist = []
            for p in params.split(","):
                p = p.strip()
                if not p or p == "void":
                    continue
                pm = re.match(r"^(.*?)([A-Za-z_][A-Za-z0-9_]*)\s*$", p, re.S)
                if not pm:
                    plist.append((p, None))
                    continue
                head, last = pm.group(1).strip(), pm.group(2)
                # C allows an unnamed parameter, and this header uses that 46
                # times. A lone token in a parameter list can only be a type.
                plist.append((last, None) if head == "" else (head, last))
            funcptrs.append((name, ret, plist))

        elif body.startswith("enum") and "{" in body:
            nm = re.search(r"}\s*([A-Za-z_][A-Za-z0-9_]*)\s*$", body)
            if nm:
                aliases[nm.group(1)] = "int32_t"       # a C enum is an int

        else:
            # The star may be attached to the name - `typedef const void
            # *GDExtensionStringNamePtr;` - so it cannot be required to have
            # whitespace before the identifier.
            am = re.match(r"^(.*?)(\**)\s*([A-Za-z_][A-Za-z0-9_]*)\s*$", body, re.S)
            if am:
                base, stars, name = am.group(1).strip(), am.group(2), am.group(3)
                aliases[name] = (base + " " + stars).strip() if stars else base

    return structs, funcptrs, aliases


def resolve(ctype, aliases, funcptr_names, struct_names):
    """(kind, pb_suffix, base_name) where kind is 'ptr', 'scalar' or 'struct'."""
    t = " ".join(ctype.split())
    seen = set()
    # Walk the typedef chain, re-testing at every step: GDExtensionStringNamePtr
    # is a name that expands to `const void *`, so the star only appears AFTER
    # the alias is followed.
    while True:
        if "*" in t:
            return "ptr", "", None
        if t in SCALARS:
            suffix, _ = SCALARS[t]
            return "scalar", suffix, t
        if t in funcptr_names:
            return "ptr", "", None
        if t in struct_names:
            return "struct", "", t
        if t in aliases and t not in seen:
            seen.add(t)
            t = " ".join(aliases[t].split())
            continue
        # A field of unknown width would be a silent layout error, so say so.
        raise SystemExit("gen_interface: cannot resolve C type %r" % ctype)


def pb_field(ctype, name, aliases, funcptr_names, struct_names):
    try:
        kind, suffix, base = resolve(ctype, aliases, funcptr_names, struct_names)
    except SystemExit as e:
        raise SystemExit("%s  [struct field %s]" % (e, name))
    if kind == "ptr":
        return "*" + name
    if kind == "struct":
        return name + "." + base
    return name + "." + suffix


def main():
    text = open(HEADER, encoding="utf-8").read()
    structs, funcptrs, aliases = parse(text)
    funcptr_names = {f[0] for f in funcptrs}
    struct_names = {s[0] for s in structs}

    out = []
    out.append("; " + "=" * 75)
    out.append("; gdextension_interface.pbi - GENERATED FILE. Do not edit by hand.")
    out.append(";")
    out.append(";   tools/gen_interface.py            regenerate from the header")
    out.append(";   tools/gen_interface.py --check    fail if this file is out of date")
    out.append(";")
    out.append("; Source: gdextension_interface.h, Godot's own header, vendored beside")
    out.append("; this file. The declarations below are derived from it rather than")
    out.append("; transcribed by hand, so they cannot drift from it.")
    out.append(";")
    out.append("; Why they exist at all: PureBasic cannot use the header's types. It")
    out.append("; mangles its own structures to s_<lowercased-name> with f_<field>")
    out.append("; members and generates field access against that, so every structure")
    out.append("; and every function-pointer type the extension touches needs a")
    out.append("; PureBasic declaration. This is those declarations, generated.")
    out.append("; " + "=" * 75)
    out.append("")

    for name, fields in structs:
        out.append("Structure %s Align #PB_Structure_AlignC" % name)
        for ctype, fname in fields:
            out.append("  " + pb_field(ctype, fname, aliases, funcptr_names, struct_names))
        out.append("EndStructure")
        out.append("")

    for name, ret, params in funcptrs:
        parts = []
        for idx, (ctype, pname) in enumerate(params):
            if pname is None:
                pname = "p%d" % idx          # unnamed in C; nothing reads the name
            try:
                kind, suffix, _ = resolve(ctype, aliases, funcptr_names, struct_names)
            except SystemExit as e:
                raise SystemExit("%s  [prototype %s, param %s]" % (e, name, pname))
            parts.append("*" + pname if kind == "ptr" else pname + "." + suffix)
        out.append("Prototype %s(%s)" % (name, ", ".join(parts)))
    out.append("")

    result = "\n".join(out)
    if "--check" in sys.argv:
        current = open(OUTPUT, encoding="utf-8").read() if os.path.exists(OUTPUT) else ""
        if current.strip() != result.strip():
            print("gdextension_interface.pbi is out of date: run tools/gen_interface.py",
                  file=sys.stderr)
            return 1
        print("gdextension_interface.pbi matches %s (%d structures, %d prototypes)"
              % (os.path.basename(HEADER), len(structs), len(funcptrs)))
        return 0

    open(OUTPUT, "w", encoding="utf-8").write(result)
    print("wrote %s: %d structures, %d prototypes" % (OUTPUT, len(structs), len(funcptrs)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
