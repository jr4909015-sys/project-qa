import { Outlet } from 'react-router-dom';
import Navbar from '../components/common/Navbar.jsx';
import Sidebar from '../components/common/Sidebar.jsx';

export default function UserLayout() {
  return <div className="app-shell"><Sidebar /><div className="main-column"><Navbar /><main className="page-content"><Outlet /></main></div></div>;
}