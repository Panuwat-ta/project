import {
  adminProfileSchema,
  adminSessionListSchema,
  auditLogListSchema,
  dashboardSchema,
  exportJobListSchema,
  healthSchema,
  modelListSchema,
  reportListSchema,
  searchResponseSchema,
  userListSchema,
} from '../../../src/schemas/admin.js';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

// Standalone live contract check. Run from admin-portal/:
//   node .impeccable/qa-loop/scripts/live-contract-check.mjs
// Prints only `SCHEMA <name> PASS|FAIL`. Never prints credentials, tokens, or values.

function loadEnv(root) {
  const env = {};
  try {
    for (const line of readFileSync(join(root, '.env'), 'utf8').split('\n')) {
      const m = /^([A-Za-z_][A-Za-z0-9_]*)=(.*)$/.exec(line.trim());
      if (m) env[m[1]] = m[2];
    }
  } catch {
    // No .env: fall through to failure below.
  }
  return env;
}

const ROOT = new URL('../../..', import.meta.url).pathname;
const env = loadEnv(ROOT);
const base = env.VITE_BACKEND_TARGET || 'http://localhost:8000';
const api = `${base}/api/v1`;
const username = env.VITE_DEFAULT_ADMIN_USERNAME;
const password = env.VITE_DEFAULT_ADMIN_PASSWORD;

if (!username || !password) {
  console.log('SCHEMA login FAIL missing-dev-credentials');
  process.exit(1);
}

const form = new URLSearchParams({ username, password });
let login;
try {
  login = await fetch(`${api}/admin/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: form,
  });
} catch {
  console.log('SCHEMA login FAIL backend-unreachable');
  process.exit(1);
}
if (!login.ok) {
  console.log(`SCHEMA login FAIL http-${login.status}`);
  process.exit(1);
}
const { access_token } = await login.json();
if (!access_token) {
  console.log('SCHEMA login FAIL no-token');
  process.exit(1);
}
console.log('SCHEMA login PASS');

const H = { Authorization: `Bearer ${access_token}` };
const checks = [
  ['dashboard', '/admin/dashboard', dashboardSchema],
  ['health', '/admin/health', healthSchema],
  ['reports', '/admin/reports?status=pending&limit=5', reportListSchema],
  ['users', '/admin/users?page=1&limit=1', userListSchema],
  ['models', '/admin/models', modelListSchema],
  ['audit', '/admin/audit-logs?page=1&limit=1', auditLogListSchema],
  ['me', '/admin/me', adminProfileSchema],
  ['sessions', '/admin/sessions', adminSessionListSchema],
  ['search', '/admin/search?q=test', searchResponseSchema],
  ['exports', '/admin/dataset/export-jobs?page=1&limit=5', exportJobListSchema],
];

let failed = 0;
for (const [name, path, schema] of checks) {
  try {
    const res = await fetch(api + path, { headers: H });
    if (!res.ok) {
      console.log(`SCHEMA ${name} FAIL http-${res.status}`);
      failed += 1;
      continue;
    }
    const result = schema.safeParse(await res.json());
    console.log(`SCHEMA ${name} ${result.success ? 'PASS' : 'FAIL schema-mismatch'}`);
    if (!result.success) failed += 1;
  } catch {
    console.log(`SCHEMA ${name} FAIL fetch-error`);
    failed += 1;
  }
}
process.exit(failed === 0 ? 0 : 1);
