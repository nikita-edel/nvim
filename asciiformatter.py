import sys
from pathlib import Path

def convert_to_lua_array(input_file: Path):
    with input_file.open("r", encoding="utf-8") as f:
        lines = f.readlines()
    lua_lines = ['    "{}",'.format(line.rstrip().replace('\\', '\\\\').replace('"', '\\"')) for line in lines]
    lua_output = ["{"] + lua_lines + ["}"]
    return "\n".join(lua_output)

def main():
    if len(sys.argv) != 2:
        print("Usage: python util.py <ascii_file.txt>")
        sys.exit(1)
    input_path = Path(sys.argv[1])
    if not input_path.is_file():
        print(f"File not found: {input_path}")
        sys.exit(1)
    output = convert_to_lua_array(input_path)
    print(output)

if __name__ == "__main__":
    main()
