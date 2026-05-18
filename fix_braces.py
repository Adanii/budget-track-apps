import re
import os

fixes = [
    ('lib/features/transaction/presentation/screens/add_adjustment_screen.dart', 234),
    ('lib/features/transaction/presentation/screens/add_adjustment_screen.dart', 463),
    ('lib/features/transaction/presentation/screens/add_income_screen.dart', 274),
    ('lib/features/transaction/presentation/screens/history_screen.dart', 48),
    ('lib/features/transaction/presentation/screens/transfer_screen.dart', 206),
]

# Pattern: if (condition) statement; -> if (condition) { statement; }
# Only single-statement ifs without braces
PATTERN = re.compile(
    r'([ \t]*)(if\s*\([^)]+\))\s*\n(\s+)([^\{][^\n]+;)',
    re.MULTILINE
)

def add_braces(content):
    def replacer(m):
        indent = m.group(1)
        condition = m.group(2)
        inner_indent = m.group(3)
        statement = m.group(4)
        return f'{indent}{condition} {{\n{inner_indent}{statement}\n{indent}}}'
    return PATTERN.sub(replacer, content)

for filepath, _ in set((f, l) for f, l in fixes):
    if not os.path.exists(filepath):
        print(f'  MISSING: {filepath}')
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    new_content = add_braces(content)
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'  fixed: {filepath}')
    else:
        print(f'  no change (complex pattern): {filepath}')
