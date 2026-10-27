import { useEffect, useState } from 'react';
import { ArrowUpRight, Plus } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth.js';
import { equipmentService } from '../../services/equipmentService.js';
import { reservationService } from '../../services/reservationService.js';
import { laboratoryService } from '../../services/laboratoryService.js';
import StatCard from '../../components/dashboard/StatCard.jsx';
import RecentReservations from '../../components/dashboard/RecentReservations.jsx';
import Footer from '../../components/common/Footer.jsx';

export default function DashboardPage() {
  const { user } = useAuth();
  const [reservations, setReservations] = useState([]);
  const [available, setAvailable] = useState(null);
  useEffect(() => {
    Promise.all([reservationService.list(), equipmentService.list(), laboratoryService.list()])
      .then(([reservationResponse, equipmentResponse, labResponse]) => {
        setReservations(reservationResponse.data.results ?? reservationResponse.data);
        const equipment = equipmentResponse.data.results ?? equipmentResponse.data;
        const labs = labResponse.data.results ?? labResponse.data;
        setAvailable(equipment.reduce((sum, item) => sum + (item.available_quantity ?? item.quantity), 0) + labs.length);
      })
      .catch(() => setAvailable(0));
  }, []);
  const pending = reservations.filter((item) => item.status === 'pending').length;
  const active = reservations.filter((item) => ['pending', 'approved'].includes(item.status)).length;
  return <><div className="welcome-row"><div><p className="eyebrow">{new Intl.DateTimeFormat(undefined, { weekday: 'long', month: 'long', day: 'numeric' }).format(new Date()).toUpperCase()}</p><h1>Welcome, <em>{user?.first_name || user?.username || 'student'}.</em></h1><p className="welcome-copy">Find the resources you need for today's work.</p></div><Link className="button-primary create-button" to="/reservations/new"><Plus size={17} /> New reservation</Link></div><section className="stats-grid"><StatCard label="ACTIVE RESERVATIONS" value={active} note={`${reservations.length} total requests`} /><StatCard label="AWAITING APPROVAL" value={pending} note="Your pending requests" tone="yellow" /><StatCard label="AVAILABLE RESOURCES" value={available ?? '…'} note="Equipment units and labs" tone="blue" /></section><section className="quick-links"><Link to="/equipment"><span className="quick-number">01</span><div><strong>Browse equipment</strong><small>Check quantities and condition</small></div><ArrowUpRight size={18} /></Link><Link to="/laboratories"><span className="quick-number">02</span><div><strong>Explore laboratories</strong><small>Check capacity, facilities and times</small></div><ArrowUpRight size={18} /></Link></section><RecentReservations reservations={reservations} /><Footer /></>;
}