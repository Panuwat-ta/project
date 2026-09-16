import { RouterProvider } from 'react-router-dom';
import AppProviders from './AppProviders.jsx';
import { router } from './router.jsx';

export default function App() {
  return (
    <AppProviders>
      <RouterProvider router={router} />
    </AppProviders>
  );
}
