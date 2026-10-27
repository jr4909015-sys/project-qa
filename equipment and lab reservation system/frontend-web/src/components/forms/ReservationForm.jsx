import { useEffect, useState } from 'react';
import { equipmentService } from '../../services/equipmentService.js';
import { laboratoryService } from '../../services/laboratoryService.js';
import { reservationService } from '../../services/reservationService.js';

function toLocalInput(date) {
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
  return local.toISOString().slice(0, 16);
}

function formatSlot(value) {
  return new Date(value).toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' });
}

export default function ReservationForm({ onSubmit, error, busy }) {
  const [resourceType, setResourceType] = useState('equipment');
  const [equipment, setEquipment] = useState([]);
  const [laboratories, setLaboratories] = useState([]);
  const [resourceId, setResourceId] = useState('');
  const [date, setDate] = useState('');
  const [start, setStart] = useState('');
  const [end, setEnd] = useState('');
  const [quantity, setQuantity] = useState('1');
  const [attendees, setAttendees] = useState('1');
  const [availability, setAvailability] = useState(null);
  const [loadError, setLoadError] = useState('');
  const [availabilityError, setAvailabilityError] = useState('');

  useEffect(() => {
    Promise.all([equipmentService.list(), laboratoryService.list()])
      .then(([equipmentResponse, laboratoryResponse]) => {
        setEquipment(equipmentResponse.data.results ?? equipmentResponse.data);
        setLaboratories(laboratoryResponse.data.results ?? laboratoryResponse.data);
      })
      .catch(() => setLoadError('Resource catalogue could not be loaded.'));
  }, []);

  useEffect(() => {
    if (!resourceId || !date) {
      setAvailability(null);
      setAvailabilityError('');
      return undefined;
    }
    let cancelled = false;
    const timer = window.setTimeout(() => {
      reservationService.availability({
        resource_type: resourceType,
        resource_id: resourceId,
        date,
        utc_offset_minutes: -new Date(`${date}T00:00:00`).getTimezoneOffset(),
        quantity: resourceType === 'equipment' ? quantity : 1,
      })
        .then(({ data }) => {
          if (!cancelled) {
            setAvailability(data);
            setAvailabilityError('');
          }
        })
        .catch((requestError) => {
          if (!cancelled) {
            setAvailability(null);
            setAvailabilityError(requestError.response?.data?.detail || 'Availability could not be checked.');
          }
        });
    }, 180);
    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [resourceId, resourceType, date, quantity]);

  function submit(event) {
    event.preventDefault();
    const form = new FormData(event.currentTarget);
    onSubmit?.({
      equipment: resourceType === 'equipment' ? Number(resourceId) : null,
      laboratory: resourceType === 'laboratory' ? Number(resourceId) : null,
      start_at: new Date(start).toISOString(),
      end_at: new Date(end).toISOString(),
      purpose: form.get('purpose'),
      quantity: resourceType === 'equipment' ? Number(quantity || 1) : 1,
      attendees: Number(attendees || 1),
    });
  }

  function chooseSlot(slot) {
    const slotStart = new Date(slot.start_at);
    setStart(toLocalInput(slotStart));
    setEnd(toLocalInput(new Date(slotStart.getTime() + 30 * 60 * 1000)));
  }

  const resources = resourceType === 'equipment' ? equipment : laboratories;
  return (
    <form className="data-form" onSubmit={submit}>
      <label>
        Resource type
        <select
          value={resourceType}
          onChange={(event) => {
            setResourceType(event.target.value);
            setResourceId('');
            setAvailability(null);
          }}
        >
          <option value="equipment">Equipment</option>
          <option value="laboratory">Laboratory</option>
        </select>
      </label>
      <label>
        {resourceType === 'equipment' ? 'Equipment' : 'Laboratory'}
        <select
          value={resourceId}
          onChange={(event) => setResourceId(event.target.value)}
          required
        >
          <option value="" disabled>Select a resource</option>
          {resources.map((item) => (
            <option
              key={item.id}
              value={item.id}
              disabled={resourceType === 'equipment' && (item.available_quantity ?? item.quantity) < 1}
            >
              {item.name}{resourceType === 'equipment'
                ? ` · ${item.available_quantity ?? item.quantity} available`
                : ` · ${item.capacity} seats · ${item.building}`}
            </option>
          ))}
        </select>
      </label>
      {resourceType === 'equipment' && (
        <label>
          Quantity
          <input
            type="number"
            min="1"
            max={resources.find((item) => String(item.id) === resourceId)?.quantity}
            value={quantity}
            onChange={(event) => setQuantity(event.target.value)}
            required
          />
        </label>
      )}
      <label>
        Availability date
        <input
          type="date"
          value={date}
          onChange={(event) => setDate(event.target.value)}
          required
        />
      </label>
      {availability && (
        <fieldset className="availability-calendar">
          <legend>30-minute availability</legend>
          <div className="availability-legend">
            <span><i className="slot-dot slot-available" /> Available</span>
            <span><i className="slot-dot slot-booked" /> Booked</span>
            <span><i className="slot-dot slot-unavailable" /> Unavailable</span>
          </div>
          <div className="availability-slots">
            {availability.slots.map((slot) => (
              <button
                type="button"
                key={slot.start_at}
                className={`availability-slot slot-${slot.status}`}
                disabled={slot.status !== 'available'}
                title={slot.detail || `${slot.available_quantity ?? ''} available`}
                onClick={() => chooseSlot(slot)}
              >
                {formatSlot(slot.start_at)}
              </button>
            ))}
          </div>
        </fieldset>
      )}
      {availabilityError && <p className="form-error" role="alert">{availabilityError}</p>}
      <div className="form-pair">
        <label>Start<input type="datetime-local" value={start} onChange={(event) => setStart(event.target.value)} required /></label>
        <label>End<input type="datetime-local" value={end} onChange={(event) => setEnd(event.target.value)} required /></label>
      </div>
      <label>Attendees<input type="number" min="1" value={attendees} onChange={(event) => setAttendees(event.target.value)} required /></label>
      <label>Purpose<textarea name="purpose" required rows="3" /></label>
      {(error || loadError) && <p className="form-error" role="alert">{error || loadError}</p>}
      <button className="button-primary" disabled={busy || Boolean(loadError)}>
        {busy ? 'Submitting...' : 'Submit request'}
      </button>
    </form>
  );
}
