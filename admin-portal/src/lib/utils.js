import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs) {
  return twMerge(clsx(...inputs));
}

export function isInternalPath(url) {
  return typeof url === 'string' && url.startsWith('/') && !url.startsWith('//');
}

export function getFilenameFromDisposition(header) {
  if (!header) return null;
  const match = /filename\*?=(?:UTF-8''|")?([^";]+)/i.exec(header);
  if (!match) return null;
  try {
    return decodeURIComponent(match[1].replace(/"/g, '').trim());
  } catch {
    return match[1].replace(/"/g, '').trim();
  }
}
