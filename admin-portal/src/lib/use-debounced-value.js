import { useEffect, useRef, useState } from "react";

function normalizeDebouncedValue(value) {
  return typeof value === "string" ? value.trim() : value;
}

/**
 * Debounced value with optional side effect (e.g. reset page to 1).
 * Replaces the verbatim 300ms searchTimer copies across list pages.
 */
export function useDebouncedValue(value, delay = 300, onDebounced) {
  const initialValue = normalizeDebouncedValue(value);
  const [debounced, setDebounced] = useState(initialValue);
  const debouncedRef = useRef(initialValue);
  const onDebouncedRef = useRef(onDebounced);

  useEffect(() => {
    onDebouncedRef.current = onDebounced;
  }, [onDebounced]);

  useEffect(() => {
    const normalized = normalizeDebouncedValue(value);
    if (Object.is(normalized, debouncedRef.current)) return undefined;

    const id = setTimeout(() => {
      debouncedRef.current = normalized;
      setDebounced(normalized);
      onDebouncedRef.current?.(normalized);
    }, delay);
    return () => clearTimeout(id);
  }, [value, delay]);

  return debounced;
}
