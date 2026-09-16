import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from '../lib/query-client.js';
import { ThemeProvider } from '../components/layout/Theme.jsx';
import { ToastProvider } from '../components/ui/Toast.jsx';

export default function AppProviders({ children }) {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <ToastProvider>{children}</ToastProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}
