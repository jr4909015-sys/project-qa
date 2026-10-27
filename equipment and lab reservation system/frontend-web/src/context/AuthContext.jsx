import { createContext, useEffect, useMemo, useState } from 'react';
import { authService } from '../services/authService.js';

export const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(Boolean(localStorage.getItem('access-token')));

  useEffect(() => {
    if (!localStorage.getItem('access-token')) return;
    authService.currentUser()
      .then((currentUser) => {
        setUser({ ...currentUser, name: `${currentUser.first_name} ${currentUser.last_name}`.trim() || currentUser.username });
      })
      .catch(() => authService.logout())
      .finally(() => setLoading(false));
  }, []);

  const value = useMemo(() => ({
    user,
    loading,
    async refreshUser() {
      const currentUser = await authService.currentUser();
      const nextUser = { ...currentUser, name: `${currentUser.first_name} ${currentUser.last_name}`.trim() || currentUser.username };
      setUser(nextUser);
      return nextUser;
    },
    signIn: async (username, password) => {
      await authService.login({ username, password });
      const currentUser = await authService.currentUser();
      const nextUser = { ...currentUser, name: `${currentUser.first_name} ${currentUser.last_name}`.trim() || currentUser.username };
      localStorage.setItem('school-user', JSON.stringify(nextUser));
      setUser(nextUser);
      return nextUser;
    },
    signOut: () => {
      authService.logout();
      localStorage.removeItem('school-user');
      setUser(null);
    },
  }), [user, loading]);
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}