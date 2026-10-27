import { Bell, Search } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth.js';

export default function Navbar() {
  const { user } = useAuth();
  return <header className="topbar"><div className="breadcrumb">Campus Reserve <span>/</span> {user?.role || 'Portal'}</div><div className="topbar-actions"><button className="icon-button" aria-label="Search"><Search size={18} /></button><Link className="icon-button" aria-label="Notifications" to="/notifications"><Bell size={18} /></Link><Link className="user-badge" aria-label="Profile" to="/profile">{user?.name?.slice(0, 1).toUpperCase() || 'S'}</Link></div></header>;
}