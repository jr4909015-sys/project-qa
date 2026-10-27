import { useEffect, useState } from 'react';
import StatCard from '../../components/dashboard/StatCard.jsx';
import { reportService } from '../../services/reportService.js';

export default function AdminDashboardPage() {
  const [summary, setSummary] = useState(null);
  const [error, setError] = useState('');
  useEffect(() => {
    reportService.dashboard().then(({ data }) => setSummary(data)).catch(() => setError('Administrator access is required to view operational totals.'));
  }, []);
  return <><p className="eyebrow">ADMINISTRATION</p><h1>Operations overview</h1><p className="welcome-copy">Live reservation and resource activity.</p>{error && <p className="form-error" role="alert">{error}</p>}<section className="stats-grid admin-stats">{[
    ['EQUIPMENT TYPES', summary?.equipment_count ?? '—', 'Active inventory items'],
    ['EQUIPMENT UNITS', summary?.equipment_units ?? '—', `${summary?.available_units ?? '—'} available`],
    ['UNAVAILABLE UNITS', summary?.unavailable_units ?? '—', 'Borrowed, damaged or under maintenance', 'yellow'],
    ['LABORATORIES', summary?.laboratory_count ?? '—', 'Active rooms'],
    ['RESERVATIONS', summary?.reservation_count ?? '—', `${summary?.pending_count ?? '—'} pending`],
    ['APPROVED', summary?.approved_count ?? '—', 'Current total'],
    ['REJECTED / CANCELLED', `${summary?.rejected_count ?? '—'} / ${summary?.cancelled_count ?? '—'}`, 'Current total', 'yellow'],
    ['OVERDUE LOANS', summary?.overdue_loans ?? '—', 'Items past due', 'blue'],
  ].map(([label, value, note, tone]) => <StatCard key={label} label={label} value={value} note={note} tone={tone} />)}</section><section className="reservation-panel"><div className="section-heading"><div><p className="eyebrow">AUDIT</p><h2>Recent activity</h2></div></div>{(summary?.recent_activity ?? []).map((event, index) => <div className="reservation-row" key={`${event.action}-${index}`}><div className="item-details"><strong>{event.summary}</strong><span>{event.actor__username || 'System'} · {new Date(event.created_at).toLocaleString()}</span></div><span className="status status-approved">{event.action}</span></div>)}</section></>;
}