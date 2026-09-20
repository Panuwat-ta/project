import { useEffect, useState } from "react";

/**
 * Debounced value with optional side effect (e.g. reset page to 1).
 * Replaces the verbatim 300ms searchTimer copies across list pages.
 */
export function useDebouncedValue(value, delay = 300, onDebounced) {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const id = setTimeout(() => {
      const trimmed = typeof value === "string" ? value.trim() : value;
      setDebounced(trimmed);
      onDebounced?.(trimmed);
    }, delay);
    return () => clearTimeout(id);
  }, [value, delay, onDebounced]);

  return debounced;
}
