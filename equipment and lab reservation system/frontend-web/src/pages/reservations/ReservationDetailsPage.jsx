import { useCallback, useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { reservationService } from '../../services/reservationService.js';

const dateTime = (value) => value ? new Date(value).toLocaleString() : 'Waiting for review';

export default function ReservationDetailsPage() {
  const { id } = useParams();
  const [reservation, setReservation] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [proposedStart, setProposedStart] = useState('');
  const [proposedEnd, setProposedEnd] = useState('');

  const load = useCallback(async () => {
    try {
      const { data } = await reservationService.get(id);
      setReservation(data);
      setError('');
    } catch {
      setError('Reservation details could not be loaded.');
    }
  }, [id]);

  useEffect(() => { load(); }, [load]);

  async function requestChange(event) {
    event.preventDefault();
    setBusy(true);
    setError('');
    try {
      await reservationService.requestReschedule(id, new Date(proposedStart).toISOString(), new Date(proposedEnd).toISOString());
      setProposedStart('');
      setProposedEnd('');
      await load();
    } catch (requestError) {
      setError(requestError.response?.data?.availability?.[0] || requestError.response?.data?.detail || 'Schedule change could not be requested.');
    } finally {
      setBusy(false);
    }
  }

  if (error && !reservation) return <><p className="eyebrow">RESERVATION DETAILS</p><h1>Reservation</h1><p className="form-error" role="alert">{error}</p></>;
  if (!reservation) return <><p className="eyebrow">RESERVATION DETAILS</p><h1>Loading reservation...</h1></>;

  const complete = reservation.status === 'completed';
  const cancelled = reservation.status === 'cancelled';
  const reviewed = Boolean(reservation.reviewed_at);
  const rejected = reservation.status === 'declined';
  const steps = [
    ['Submitted', reservation.created_at, true],
    ['Under review', reservation.reviewed_at, reviewed || reservation.status === 'pending'],
    [rejected ? 'Rejected' : cancelled ? 'Cancelled' : 'Approved', reservation.reviewed_at || reservation.cancelled_at, reviewed || cancelled],
    ['Completed', reservation.completed_at, complete],
  ];
  const canReschedule = ['pending', 'approved'].includes(reservation.status) && reservation.reschedule_status !== 'pending';

  return (
    <article className="reservation-confirmation">
      <p className="eyebrow">RESERVATION DETAILS</p>
      <div className="welcome-row">
        <div>
          <h1>{reservation.equipment_name || reservation.laboratory_name || 'Reservation'}</h1>
          <p className="welcome-copy">Confirmation number: <strong>RSV-{String(reservation.id).padStart(6, '0')}</strong></p>
        </div>
        <button className="button-secondary no-print" onClick={() => window.print()}>Print confirmation</button>
      </div>
      {error && <p className="form-error" role="alert">{error}</p>}
      <p><span className={`status status-${reservation.status}`}>{reservation.status === 'declined' ? 'Rejected' : reservation.status}</span></p>
      <section className="reservation-timeline" aria-label="Reservation status timeline">
        {steps.map(([label, timestamp, reached], index) => (
          <div className={`timeline-step${reached ? ' reached' : ''}`} key={label}>
            <span className="timeline-marker">{reached ? '✓' : index + 1}</span>
            <div><strong>{label}</strong><span>{dateTime(timestamp)}</span></div>
          </div>
        ))}
      </section>
      {rejected && reservation.remarks && <p className="form-error"><strong>Reason for rejection:</strong> {reservation.remarks}</p>}
      <section className="data-form confirmation-data">
        <p><strong>Schedule:</strong> {dateTime(reservation.start_at)} – {new Date(reservation.end_at).toLocaleTimeString()}</p>
        <p><strong>Purpose:</strong> {reservation.purpose}</p>
        <p><strong>Quantity:</strong> {reservation.quantity} · <strong>Attendees:</strong> {reservation.attendees}</p>
        {reservation.remarks && !rejected && <p><strong>Staff remarks:</strong> {reservation.remarks}</p>}
      </section>
      {reservation.reschedule_status === 'pending' && (
        <p className="empty-panel">Schedule change awaiting staff approval: {dateTime(reservation.proposed_start_at)} – {dateTime(reservation.proposed_end_at)}</p>
      )}
      {reservation.reschedule_status === 'declined' && reservation.reschedule_remarks && (
        <p className="form-error"><strong>Schedule change declined:</strong> {reservation.reschedule_remarks}</p>
      )}
      {canReschedule && (
        <form className="data-form no-print" onSubmit={requestChange}>
          <h2>Request a schedule change</h2>
          <p>The current reservation stays in place until staff reviews the proposed time.</p>
          <div className="form-pair">
            <label>Proposed start<input type="datetime-local" value={proposedStart} onChange={(event) => setProposedStart(event.target.value)} required /></label>
            <label>Proposed end<input type="datetime-local" value={proposedEnd} onChange={(event) => setProposedEnd(event.target.value)} required /></label>
          </div>
          <button className="button-primary" disabled={busy}>{busy ? 'Submitting...' : 'Send for staff approval'}</button>
        </form>
      )}
    </article>
  );
}
