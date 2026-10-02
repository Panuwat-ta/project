#!/usr/bin/env python3
"""Fail closed when LCOV lacks branch data or falls below the required gate."""
import argparse
import json
from pathlib import Path


def coverage(text):
    lines_found = lines_hit = 0
    branches = []
    for line in text.splitlines():
        if line.startswith('LF:'):
            lines_found += int(line[3:])
        elif line.startswith('LH:'):
            lines_hit += int(line[3:])
        elif line.startswith('BRDA:'):
            parts = line[5:].split(',')
            if len(parts) != 4:
                raise ValueError('Malformed BRDA record')
            branches.append(parts[3] != '-' and int(parts[3]) > 0)
    if lines_found <= 0 or not branches or not 0 <= lines_hit <= lines_found:
        raise ValueError('Valid line and branch coverage are required')
    return {
        'lines_hit': lines_hit, 'lines_found': lines_found,
        'line_percent': 100 * lines_hit / lines_found,
        'branches_hit': sum(branches), 'branches_found': len(branches),
        'branch_percent': 100 * sum(branches) / len(branches),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('lcov', type=Path)
    parser.add_argument('--minimum', type=float, default=80)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if not 0 <= args.minimum <= 100:
        parser.error('minimum must be between 0 and 100')
    result = coverage(args.lcov.read_text())
    result['minimum'] = args.minimum
    result['passed'] = min(result['line_percent'], result['branch_percent']) >= args.minimum
    output = json.dumps(result, indent=2)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(output + '\n')
    print(output)
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
