#!/usr/bin/env python3
import os
import re
import plistlib

def to_camel_case(key):
    # Split by non-alphanumeric characters
    parts = re.split(r'[^a-zA-Z0-9]', key)
    if not parts:
        return ""
    res = parts[0]
    for p in parts[1:]:
        if p:
            res += p[0].upper() + p[1:]
    return res

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    ru_strings_path = os.path.join(script_dir, 'Tracker', 'ru.lproj', 'Localizable.strings')
    ru_stringsdict_path = os.path.join(script_dir, 'Tracker', 'ru.lproj', 'Localizable.stringsdict')
    output_swift_path = os.path.join(script_dir, 'Tracker', 'L10n.swift')
    
    # Parse Localizable.strings
    strings_keys = []
    if os.path.exists(ru_strings_path):
        with open(ru_strings_path, 'r', encoding='utf-8') as f:
            content = f.read()
        matches = re.findall(r'"([^"]+)"\s*=\s*"[^"]*"\s*;', content)
        strings_keys = matches

    # Parse Localizable.stringsdict
    stringsdict_keys = []
    if os.path.exists(ru_stringsdict_path):
        with open(ru_stringsdict_path, 'rb') as f:
            try:
                plist = plistlib.load(f)
                stringsdict_keys = list(plist.keys())
            except Exception as e:
                print(f"Error parsing stringsdict: {e}")

    # Generate Swift code
    code = []
    code.append("// Auto-generated file. Do not edit.")
    code.append("import Foundation")
    code.append("")
    code.append("enum L10n {")
    
    # Generate regular localized constants
    if strings_keys:
        code.append("    // MARK: - Strings")
        for key in strings_keys:
            var_name = to_camel_case(key)
            code.append(f'    static let {var_name} = NSLocalizedString("{key}", comment: "")')
        code.append("")
        
    # Generate pluralized functions
    if stringsdict_keys:
        code.append("    // MARK: - Plurals")
        for key in stringsdict_keys:
            func_name = to_camel_case(key)
            code.append(f"    static func {func_name}(_ count: Int) -> String {{")
            code.append(f'        let format = NSLocalizedString("{key}", comment: "")')
            code.append("        return String.localizedStringWithFormat(format, count)")
            code.append("    }")
            
    code.append("}")
    code.append("")
    
    # Write output
    with open(output_swift_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(code))
    
    print(f"Generated L10n.swift with {len(strings_keys)} strings and {len(stringsdict_keys)} plurals.")

if __name__ == '__main__':
    main()
