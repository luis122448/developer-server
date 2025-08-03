import re

input_file = '/srv/developer-server/oracle/init/TABLES_DDL.sql'
output_file = '/srv/developer-server/oracle/init/TABLES_DDL_fixed.sql'

def fix_ddl_script(input_path, output_path):
    with open(input_path, 'r') as f:
        content = f.read()

    # Remove COLLATE "USING_NLS_COMP" and DEFAULT COLLATION "USING_NLS_COMP"
    content = re.sub(r'COLLATE "USING_NLS_COMP"', '', content)
    content = re.sub(r'DEFAULT COLLATION "USING_NLS_COMP"', '', content)

    fixed_lines = []
    for line in content.splitlines():
        # Check if the line ends a CREATE TABLE, ALTER TRIGGER, or ALTER TABLE statement and doesn't have a semicolon
        if (re.search(r'CREATE TABLE .*?\)\s*$', line) or 
            re.search(r'ALTER TRIGGER .*? ENABLE\s*$', line) or 
            re.search(r'ALTER TABLE .*? ENABLE\s*$', line)) and not line.strip().endswith(';'):
            fixed_lines.append(line + ';')
        else:
            fixed_lines.append(line)
    content = "\n".join(fixed_lines)

    with open(output_path, 'w') as f:
        f.write(content)

    print(f"Fixed DDL script saved to: {output_path}")

if __name__ == "__main__":
    fix_ddl_script(input_file, output_file)