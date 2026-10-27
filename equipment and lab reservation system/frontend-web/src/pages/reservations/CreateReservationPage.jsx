import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import ReservationForm from '../../components/forms/ReservationForm.jsx';
import { reservationService } from '../../services/reservationService.js';

export default function CreateReservationPage() {
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const navigate = useNavigate();
  async function submit(values) {
    setBusy(true);
    setError('');
    try {
      await reservationService.create(values);
      navigate('/reservations');
    } catch (requestError) {
      const details = requestError.response?.data;
      setError(details?.availability?.[0] || details?.detail || 'Request could not be submitted. Check availability and time range.');
    } finally {
      setBusy(false);
    }
  }
  return <><p className="eyebrow">NEW REQUEST</p><h1>Reserve a resource</h1><p className="welcome-copy">Choose a resource, time, quantity and purpose.</p><ReservationForm onSubmit={submit} error={error} busy={busy} /></>;
}