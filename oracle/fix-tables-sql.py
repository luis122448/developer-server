import re

input_file = 'oracle/init/TABLES.sql'
output_file = 'oracle/init/TABLES_fix.sql'

with open(input_file, 'r', encoding='utf-8') as f:
    content = f.read()

# --- FIXES FOR QUOTED IDENTIFIERS WITH NEWLINES ---

# FIX 1: Join identifiers split across newlines (e.g., "PER\n IODO" becomes "PERIODO")
content = re.sub(r'"(\w+)\s*\n\s*(\w+)"', r'"\1\2"', content)

# FIX 2: Fix identifiers with the closing quote on the next line (e.g., "CLASE\n ")
content = re.sub(r'"(\w+)\s*\n\s*"', r'"\1"', content)

# FIX 3: Fix identifiers with the opening quote on the previous line (e.g., " \nCLASE")
content = re.sub(r'"\s*\n\s*(\w+)"', r'"\1"', content)


# --- FIX FOR STATEMENT STRUCTURE ---

# FIX 4: Join lines in column/constraint lists that are split by a newline after a comma.
content = re.sub(r',\s*\n\s*', ', ', content)


# --- GENERAL CLEANUP LOGIC ---

# The rest of your cleaning logic
lines = content.splitlines()
cleaned_lines = []
for line in lines:
    # Skip comment lines
    if re.search(r'^\s*--', line): continue
    # Skip "Table created." message from SQL*Plus
    if "Table created." in line: continue
    # Skip long numeric strings that might be metadata
    if re.fullmatch(r'\d{20,}', line.strip()): continue
    # Skip storage and sequence clauses
    if re.search(r'\b(INCREMENT BY|START WITH|CACHE|NOORDER|NOCYCLE|NOKEEP|NOSCALE|MINVALUE|MAXVALUE)\b', line): continue
    cleaned_lines.append(line)

content = '\n'.join(cleaned_lines)

# Remove unnecessary SQL options
content = re.sub(r' COLLATE "USING_NLS_COMP"', '', content)
content = re.sub(r'DEFAULT COLLATION "USING_NLS_COMP"', '', content)
content = re.sub(r'SEGMENT CREATION IMMEDIATE', '', content)

# Normalize the IDENTITY clause (preserve minimal syntax)
content = re.sub(
    r'(GENERATED\s+(?:ALWAYS|BY DEFAULT)(?:\s+ON NULL)?\s+AS IDENTITY)\b[^\n,)]*',
    r'\1',
    content
)

# Fix: Add a missing comma if "GENERATED AS IDENTITY" is followed directly by the next column
content = re.sub(
    r'(AS IDENTITY)(\s*\n\s*"[\w]+")',
    r'\1,\2',
    content
)

with open(output_file, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Cleaned SQL file saved to: {output_file}")
