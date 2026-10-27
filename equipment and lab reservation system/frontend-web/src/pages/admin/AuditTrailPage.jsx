import { useEffect, useState } from 'react';
import { auditService } from '../../services/auditService.js';

export default function AuditTrailPage() {
  const [events, setEvents] = useState([]);
  const [error, setError] = useState('');
  useEffect(() => {
    auditService.list().then(({ data }) => setEvents(data.results ?? data)).catch(() => setError('Administrator access is required to view the audit trail.'));
  }, []);
  return <><p className="eyebrow">ADMINISTRATION</p><h1>Audit trail</h1><p className="welcome-copy">Accountability record for approvals, returns and reservation changes.</p>{error && <p className="form-error" role="alert">{error}</p>}<section className="catalog-list">{events.map((event) => <article className="reservation-row" key={event.id}><div className="item-details"><strong>{event.summary}</strong><span>{event.actor_name} · {event.object_type} #{event.object_id} · {new Date(event.created_at).toLocaleString()}</span></div><span className="status status-approved">{event.action}</span></article>)}</section></>;
}