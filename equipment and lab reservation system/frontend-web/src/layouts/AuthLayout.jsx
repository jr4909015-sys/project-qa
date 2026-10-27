import { Outlet } from 'react-router-dom';

export default function AuthLayout() {
  return <div className="auth-layout"><div className="auth-aside"><span className="brand-mark">S</span><p className="eyebrow">NORTH CAMPUS</p><h1>Make space for good work.</h1></div><Outlet /></div>;
}