import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from './AuthContext.jsx';

export default function ProtectedRoute({ allowRoles, children }) {
  const { isAuthenticated, roles } = useAuth();
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (allowRoles?.length) {
    const normalized = roles.map((role) => role.replace('ROLE_', ''));
    const hasRole = allowRoles.some((role) => normalized.includes(role));
    if (!hasRole) {
      return <Navigate to="/login" replace />;
    }
  }

  return children;
}

