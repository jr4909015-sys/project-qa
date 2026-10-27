import { Navigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth.js';

export default function ProtectedRoute({ children, roles }) {
  const { user, loading } = useAuth();
  if (loading) return <div className="route-loading" role="status">Restoring your session…</div>;
  if (!user) return <Navigate to="/login" replace />;
  if (roles && !roles.includes(user.role)) return <Navigate to="/unauthorized" replace />;
  return children;
}