import subprocess
import tempfile
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from check_coverage import coverage
from audit_dependencies import pub_packages, maven_packages, query


class CoverageTests(unittest.TestCase):
    def test_branch_hits_and_unexecuted_are_counted(self):
        result = coverage('LF:10\nLH:9\nBRDA:1,0,0,4\nBRDA:1,0,1,-\nBRDA:2,0,0,0\n')
        self.assertEqual(result['branches_found'], 3)
        self.assertEqual(result['branches_hit'], 1)
        self.assertEqual(result['line_percent'], 90)
        self.assertLess(result['branch_percent'], 80)

    def test_missing_and_malformed_data_fail_closed(self):
        for value in ['LF:10\nLH:9', 'LF:0\nLH:0\nBRDA:1,0,0,1', 'LF:1\nLH:2\nBRDA:1,0,0,1', 'LF:1\nLH:1\nBRDA:invalid']:
            with self.assertRaises(ValueError):
                coverage(value)

    def test_command_fails_below_80_and_on_missing_coverage(self):
        script = Path(__file__).resolve().parents[1] / 'check_coverage.py'
        with tempfile.TemporaryDirectory() as directory:
            lcov = Path(directory) / 'lcov.info'
            for data in ['LF:10\nLH:9\nBRDA:1,0,0,1\nBRDA:1,0,1,0\n', 'LF:10\nLH:9\n']:
                lcov.write_text(data)
                result = subprocess.run([sys.executable, str(script), str(lcov)], capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
            lcov.write_text('LF:10\nLH:8\nBRDA:1,0,0,1\n')
            result = subprocess.run([sys.executable, str(script), str(lcov)], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)


class DependencyTests(unittest.TestCase):
    def test_pub_lock_parses_hosted_and_reports_sdk_exclusion(self):
        packages, sdk = pub_packages('packages:\n  example:\n    source: hosted\n    version: "1.2.3"\n  flutter:\n    source: sdk\n    version: "0.0.0"\nsdks:\n  dart: ">=3"\n')
        self.assertEqual(packages, [{'ecosystem': 'Pub', 'name': 'example', 'version': '1.2.3'}])
        self.assertEqual(sdk, ['flutter'])

    def test_unresolved_lock_is_rejected(self):
        for value in ['', 'packages:\n  example:\n    source: git\n    version: "1"\n', 'packages:\n  example:\n    source: hosted\n']:
            with self.assertRaises(ValueError):
                pub_packages(value)

    def test_maven_graph_uses_resolved_versions_and_deduplicates(self):
        packages = maven_packages('+--- group:artifact:1.0 -> 2.0\n\\--- group:artifact:2.0 (*)\n')
        self.assertEqual(packages, [{'ecosystem': 'Maven', 'name': 'group:artifact', 'version': '2.0'}])
        for value in ['', '+--- group:artifact:1.0 FAILED']:
            with self.assertRaises(ValueError):
                maven_packages(value)

    def test_query_aggregates_pages_and_preserves_package_identity(self):
        replies = iter([{'results': [{'vulns': [{'id': 'advisory-1'}], 'next_page_token': 'next'}]}, {'results': [{'vulns': [{'id': 'advisory-2'}]}]}])
        def request(body):
            return next(replies)
        item = {'ecosystem': 'Pub', 'name': 'example', 'version': '1.0'}
        result = query([item], request)
        self.assertEqual([value['id'] for value in result], ['advisory-1', 'advisory-2'])
        self.assertTrue(all(value['name'] == 'example' for value in result))

    def test_malformed_responses_and_pagination_loops_fail_closed(self):
        item = {'ecosystem': 'Pub', 'name': 'example', 'version': '1.0'}
        for response in [{}, {'results': []}, {'results': ['bad']}, {'results': [{'vulns': [{}]}]}]:
            with self.assertRaises(ValueError):
                query([item], lambda body: response)
        with self.assertRaises(ValueError):
            query([item], lambda body: {'results': [{'next_page_token': 'same'}]})


if __name__ == '__main__':
    unittest.main()
