import { NavLink } from 'react-router-dom';
import { BookOpenCheck, FlaskConical, LayoutDashboard, Package, ShieldCheck, Archive, CircleAlert } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth.js';

const links = [
  { to: '/', label: 'Overview', icon: LayoutDashboard },
  { to: '/equipment', label: 'Equipment', icon: Package },
  { to: '/laboratories', label: 'Laboratories', icon: FlaskConical },
  { to: '/reservations', label: 'My reservations', icon: BookOpenCheck },
  { to: '/issues', label: 'Report a problem', icon: CircleAlert },
];

export default function Sidebar() {
  const { user } = useAuth();
  const adminLinks = user?.role === 'admin' || user?.role === 'staff'
    ? [{ to: '/admin', label: 'Admin overview', icon: ShieldCheck }, { to: '/admin/reservations', label: 'Approvals', icon: BookOpenCheck }, { to: '/admin/equipment', label: 'Inventory', icon: Package }, { to: '/admin/loans', label: 'Loans and returns', icon: Archive }, { to: '/admin/laboratories', label: 'Rooms', icon: FlaskConical }, { to: '/admin/users', label: 'Users', icon: LayoutDashboard }, { to: '/admin/reports', label: 'Reports', icon: BookOpenCheck }, { to: '/admin/audit', label: 'Audit trail', icon: ShieldCheck }]
    : [];
  return <aside className="sidebar"><div className="brand"><span className="brand-mark">S</span><span>Campus<span className="brand-light">Reserve</span></span></div><div className="nav-label">WORKSPACE</div><nav>{links.map(({ to, label, icon: Icon }) => <NavLink key={to} to={to} end={to === '/'} className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}><Icon size={18} strokeWidth={1.8} /><span>{label}</span></NavLink>)}</nav>{adminLinks.length > 0 && <><div className="nav-label admin-nav-label">MANAGEMENT</div><nav>{adminLinks.map(({ to, label, icon: Icon }) => <NavLink key={to} to={to} end={to === '/admin'} className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}><Icon size={18} strokeWidth={1.8} /><span>{label}</span></NavLink>)}</nav></>}<div className="sidebar-bottom"><div className="term-label">NORTH CAMPUS <span>2025 / 26</span></div></div></aside>;
}