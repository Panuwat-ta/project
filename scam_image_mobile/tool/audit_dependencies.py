#!/usr/bin/env python3
"""Audit resolved Pub/Maven versions using the public OSV API; fail on errors.
API: https://google.github.io/osv.dev/post-v1-querybatch/
Only public package names/versions are sent. SDK packages are reported separately.
"""
import argparse
import datetime
import json
import re
import urllib.request
from pathlib import Path


def pub_packages(text):
    packages, sdk = [], []
    for name, body in re.findall(r'^  ([\w-]+):\n(.*?)(?=^  [\w-]+:|^sdks:|\Z)', text, re.M | re.S):
        source = re.search(r'^    source: (\S+)$', body, re.M)
        version = re.search(r'^    version: [\"\']?([^\"\'\n]+)', body, re.M)
        if not source or not version:
            raise ValueError(f'Unresolved package {name}')
        if source[1] == 'sdk':
            sdk.append(name)
        elif source[1] == 'hosted':
            packages.append({'ecosystem': 'Pub', 'name': name, 'version': version[1]})
        else:
            raise ValueError(f'Unsupported source for {name}: {source[1]}')
    if not packages:
        raise ValueError('No resolved Pub packages found')
    return packages, sdk


def maven_packages(text):
    if 'FAILED' in text:
        raise ValueError('Gradle dependency resolution failed')
    packages = set()
    for line in text.splitlines():
        match = re.search(r'[+\\]--- ([\w.-]+):([\w.-]+):([^\s]+)(?: -> ([^\s]+))?', line)
        if not match:
            continue
        group, name, version, resolved = match.groups()
        if resolved:
            if ':' in resolved:
                group, name, version = resolved.split(':')
            else:
                version = resolved
        if any(char in version for char in '{}[]()+'):
            raise ValueError(f'Unresolved Maven version {group}:{name}')
        packages.add((group + ':' + name, version))
    if not packages:
        raise ValueError('No resolved Maven packages found')
    return [{'ecosystem': 'Maven', 'name': name, 'version': version} for name, version in sorted(packages)]


def post_json(body):
    request = urllib.request.Request('https://api.osv.dev/v1/querybatch', data=json.dumps(body).encode(), headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(request, timeout=45) as response:
        return json.load(response)


def query(packages, request=post_json):
    findings = []
    for start in range(0, len(packages), 128):
        pending = [(item, None) for item in packages[start:start + 128]]
        pages_seen = set()
        while pending:
            queries = []
            for item, token in pending:
                payload = {'package': {'ecosystem': item['ecosystem'], 'name': item['name']}, 'version': item['version']}
                if token:
                    payload['page_token'] = token
                queries.append(payload)
            results = request({'queries': queries}).get('results')
            if not isinstance(results, list) or len(results) != len(pending):
                raise ValueError('Incomplete OSV response')
            next_pending = []
            for (item, _), result in zip(pending, results):
                if not isinstance(result, dict):
                    raise ValueError('Malformed OSV result')
                for vuln in result.get('vulns', []):
                    if not isinstance(vuln, dict) or not vuln.get('id'):
                        raise ValueError('Malformed vulnerability entry')
                    findings.append({**item, 'id': vuln['id']})
                token = result.get('next_page_token')
                if token:
                    key = (item['ecosystem'], item['name'], item['version'], token)
                    if key in pages_seen:
                        raise ValueError('Repeated OSV pagination token')
                    pages_seen.add(key)
                    next_pending.append((item, token))
            pending = next_pending
    return findings


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--lock', type=Path, default=Path('pubspec.lock'))
    parser.add_argument('--gradle-report', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = {'checked_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'status': 'error', 'source': 'https://api.osv.dev/v1/querybatch'}
    try:
        packages, sdk = pub_packages(args.lock.read_text())
        packages += maven_packages(args.gradle_report.read_text())
        findings = query(packages)
        result.update(status='failed' if findings else 'passed', packages=packages, excluded_sdk_packages=sdk, findings=findings)
    except Exception as error:
        result['error'] = str(error)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'status': result['status'], 'packages': len(result.get('packages', [])), 'findings': len(result.get('findings', [])), 'report': str(args.output)}))
    return 0 if result['status'] == 'passed' else 1


if __name__ == '__main__':
    raise SystemExit(main())
