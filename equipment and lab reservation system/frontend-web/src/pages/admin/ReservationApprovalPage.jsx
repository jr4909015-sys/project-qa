import { useCallback, useEffect, useState } from 'react';
import { reservationService } from '../../services/reservationService.js';

export default function ReservationApprovalPage() {
  const [requests, setRequests] = useState([]);
  const [rescheduleRequests, setRescheduleRequests] = useState([]);
  const [remarks, setRemarks] = useState({});
  const [error, setError] = useState('');
  const load = useCallback(async () => {
    try {
      const { data } = await reservationService.list();
      const rows = data.results ?? data;
      setRequests(rows.filter((item) => item.status === 'pending'));
      setRescheduleRequests(rows.filter((item) => item.reschedule_status === 'pending'));
      setError('');
    } catch {
      setError('Could not load requests. Confirm that you are signed in as an administrator.');
    }
  }, []);
  useEffect(() => { load(); }, [load]);

  async function review(id, decision) {
    try {
      await reservationService.review(id, decision, remarks[id] || '');
      await load();
    } catch (reviewError) {
      setError(reviewError.response?.data?.availability?.[0] || 'The request could not be updated.');
    }
  }

  async function reviewReschedule(id, decision) {
    try {
      await reservationService.reviewReschedule(id, decision, remarks[id] || '');
      await load();
    } catch (reviewError) {
      setError(reviewError.response?.data?.availability?.[0] || 'Schedule change could not be updated.');
    }
  }

  return <>
    <p className="eyebrow">ADMINISTRATION</p>
    <div className="welcome-row"><div><h1>Approval queue</h1><p className="welcome-copy">Review reservations and requested schedule changes from web and mobile.</p></div></div>
    {error && <p className="form-error" role="alert">{error}</p>}
    <h2>Reservation requests</h2>
    <section className="catalog-list">
      {requests.length === 0 && !error && <p className="empty-panel">No requests are awaiting approval.</p>}
      {requests.map((request) => <article className="approval-row" key={request.id}>
        <div><p className="eyebrow">{request.requester_name || `User ${request.requester}`}</p><strong>{request.equipment_name || request.laboratory_name || `Resource ${request.equipment || request.laboratory}`}</strong><span>{new Date(request.start_at).toLocaleString()} · {request.quantity} units · {request.attendees} attendees</span><span>{request.purpose}</span><label className="remarks-field">Review remarks<textarea rows="2" value={remarks[request.id] || ''} onChange={(event) => setRemarks((current) => ({ ...current, [request.id]: event.target.value }))} /></label></div>
        <div className="approval-actions"><button className="button-secondary" onClick={() => review(request.id, 'declined')}>Reject</button><button className="button-primary" onClick={() => review(request.id, 'approved')}>Approve</button></div>
      </article>)}
    </section>
    <h2>Schedule change requests</h2>
    <section className="catalog-list">
      {rescheduleRequests.length === 0 && <p className="empty-panel">No schedule changes are awaiting approval.</p>}
      {rescheduleRequests.map((request) => <article className="approval-row" key={`change-${request.id}`}>
        <div><p className="eyebrow">{request.requester_name || `User ${request.requester}`} · RSV-{String(request.id).padStart(6, '0')}</p><strong>{request.equipment_name || request.laboratory_name}</strong><span>Current: {new Date(request.start_at).toLocaleString()} – {new Date(request.end_at).toLocaleTimeString()}</span><span>Proposed: {new Date(request.proposed_start_at).toLocaleString()} – {new Date(request.proposed_end_at).toLocaleTimeString()}</span><label className="remarks-field">Remarks<textarea rows="2" value={remarks[request.id] || ''} onChange={(event) => setRemarks((current) => ({ ...current, [request.id]: event.target.value }))} /></label></div>
        <div className="approval-actions"><button className="button-secondary" onClick={() => reviewReschedule(request.id, 'declined')}>Decline change</button><button className="button-primary" onClick={() => reviewReschedule(request.id, 'approved')}>Approve change</button></div>
      </article>)}
    </section>
  </>;
}