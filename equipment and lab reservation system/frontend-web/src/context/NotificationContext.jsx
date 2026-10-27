import { createContext, useCallback, useState } from 'react';

export const NotificationContext = createContext(null);

export function NotificationProvider({ children }) {
  const [notifications, setNotifications] = useState([]);
  const notify = useCallback((message, type = 'info') => {
    const id = `${Date.now()}-${Math.random()}`;
    setNotifications((current) => [...current, { id, message, type }]);
    window.setTimeout(() => setNotifications((current) => current.filter((item) => item.id !== id)), 4000);
  }, []);
  return <NotificationContext.Provider value={{ notifications, notify }}>{children}</NotificationContext.Provider>;
}