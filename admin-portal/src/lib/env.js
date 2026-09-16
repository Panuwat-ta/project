const env = import.meta.env ?? {};

export const API_BASE_URL = env.VITE_API_BASE_URL ?? '/api/v1';
export const APP_ENV = env.VITE_APP_ENV ?? 'production';
export const STORAGE_URL = env.VITE_STORAGE_URL ?? '';
export const WS_URL = env.VITE_WS_URL ?? '';
export const IS_DEV = APP_ENV === 'development';
export const DEV_DEFAULT_USERNAME = IS_DEV ? (env.VITE_DEFAULT_ADMIN_USERNAME ?? '') : '';
export const DEV_DEFAULT_PASSWORD = IS_DEV ? (env.VITE_DEFAULT_ADMIN_PASSWORD ?? '') : '';
