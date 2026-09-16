import '@testing-library/jest-dom/vitest';
import { cleanup } from '@testing-library/react';
import { afterAll, afterEach, beforeAll } from 'vitest';
import { tokenStore } from '../lib/api-client.js';
import { server } from './server.js';

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => {
  server.resetHandlers();
  cleanup();
  tokenStore.clear();
  window.localStorage.clear();
  window.sessionStorage.clear();
});
afterAll(() => server.close());
