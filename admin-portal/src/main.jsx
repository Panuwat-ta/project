import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'
import { registerAdminSiteTools } from './lib/webmcp.js'

void registerAdminSiteTools().catch((error) => {
  console.warn('WebMCP site tool registration failed', error)
})

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
