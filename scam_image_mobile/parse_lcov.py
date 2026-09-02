import sys

def parse_lcov(file_path):
    total_lines = 0
    covered_lines = 0
    with open(file_path, 'r') as f:
        for line in f:
            if line.startswith('DA:'):
                parts = line.strip().split(',')
                total_lines += 1
                if int(parts[1]) > 0:
                    covered_lines += 1
    
    if total_lines == 0:
        print("No lines found.")
    else:
        coverage = (covered_lines / total_lines) * 100
        print(f"Total Lines: {total_lines}")
        print(f"Covered Lines: {covered_lines}")
        print(f"Coverage: {coverage:.2f}%")

if __name__ == '__main__':
    parse_lcov('coverage/lcov.info')
