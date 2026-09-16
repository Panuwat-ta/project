import { Outlet } from 'react-router-dom';
import { AuthProvider } from '../features/auth/AuthContext.jsx';

/** Provides auth state to every route below (login + protected shell share one bootstrap). */
export default function RootProviders() {
  return (
    <AuthProvider>
      <Outlet />
    </AuthProvider>
  );
}
