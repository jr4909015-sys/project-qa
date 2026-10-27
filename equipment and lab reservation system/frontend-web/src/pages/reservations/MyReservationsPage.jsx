import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { reservationService } from '../../services/reservationService.js';

export default function MyReservationsPage() {
  const [reservations, setReservations] = useState([]);
  const [status, setStatus] = useState('all');
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [error, setError] = useState('');
  const load = useCallback(async () => {
    try {
      const { data } = await reservationService.list();
      setReservations(data.results ?? data);
      setError('');
    } catch {
      setError('Reservations could not be loaded.');
    }
  }, []);
  useEffect(() => { load(); }, [load]);

  async function cancel(id) {
    try {
      await reservationService.cancel(id);
      await load();
    } catch (requestError) {
      setError(requestError.response?.data?.status?.[0] || requestError.response?.data?.detail || 'This reservation can no longer be cancelled.');
    }
  }

  const filtered = useMemo(() => reservations.filter((item) => {
    const day = item.start_at.slice(0, 10);
    return (status === 'all' || item.status === status)
      && (!fromDate || day >= fromDate)
      && (!toDate || day <= toDate);
  }), [reservations, status, fromDate, toDate]);

  return <>
    <p className="eyebrow">YOUR REQUESTS</p>
    <div className="welcome-row"><div><h1>My reservations</h1><p className="welcome-copy">Track decisions, remarks and upcoming schedules.</p></div><Link className="button-primary" to="/reservations/new">New reservation</Link></div>
    {error && <p className="form-error" role="alert">{error}</p>}
    <div className="catalog-filters reservation-filters">
      <label>Status<select value={status} onChange={(event) => setStatus(event.target.value)}><option value="all">All statuses</option><option value="pending">Submitted</option><option value="approved">Approved</option><option value="declined">Rejected</option><option value="completed">Completed</option><option value="cancelled">Cancelled</option></select></label>
      <label>From<input type="date" value={fromDate} onChange={(event) => setFromDate(event.target.value)} /></label>
      <label>To<input type="date" min={fromDate || undefined} value={toDate} onChange={(event) => setToDate(event.target.value)} /></label>
    </div>
    <section className="catalog-list">
      {filtered.length === 0 && <p className="empty-panel">{reservations.length ? 'No reservations match these filters.' : 'No reservations yet.'}</p>}
      {filtered.map((reservation) => <article className="catalog-row" key={reservation.id}>
        <div className="item-symbol">{reservation.equipment ? 'E' : 'L'}</div>
        <div className="item-details">
          <strong>{reservation.equipment_name || reservation.laboratory_name || `Resource ${reservation.equipment || reservation.laboratory}`}</strong>
          <span>RSV-{String(reservation.id).padStart(6, '0')} · {new Date(reservation.start_at).toLocaleString()} – {new Date(reservation.end_at).toLocaleTimeString()}</span>
          <span>{reservation.purpose}</span>
          {reservation.remarks && <span>{reservation.status === 'declined' ? 'Rejection reason: ' : 'Review: '}{reservation.remarks}</span>}
          {reservation.reschedule_status === 'pending' && <span>Schedule change awaiting staff approval</span>}
        </div>
        <span className={`status status-${reservation.status}`}>{reservation.status === 'declined' ? 'Rejected' : reservation.status}</span>
        <Link className="text-button" to={`/reservations/${reservation.id}`}>Details / print</Link>
        {['pending', 'approved'].includes(reservation.status) && <button className="text-button" onClick={() => cancel(reservation.id)}>Cancel</button>}
      </article>)}
    </section>
  </>;
}
