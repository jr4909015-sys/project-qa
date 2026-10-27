import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { laboratoryService } from '../../services/laboratoryService.js';

export default function LaboratoryDetailsPage() {
  const { id } = useParams();
  const [room, setRoom] = useState(null);
  const [startAt, setStartAt] = useState('');
  const [endAt, setEndAt] = useState('');
  const [availability, setAvailability] = useState(null);
  useEffect(() => { laboratoryService.get(id).then(({ data }) => setRoom(data)); }, [id]);
  async function checkAvailability() {
    if (!startAt || !endAt) return;
    const { data } = await laboratoryService.availability(id, new Date(startAt).toISOString(), new Date(endAt).toISOString());
    setAvailability(data.available);
  }
  if (!room) return <p>Loading laboratory…</p>;
  return <><p className="eyebrow">LABORATORY DETAILS</p><h1>{room.name}</h1><p className="welcome-copy">{room.building} · {room.room_number} · Capacity {room.capacity}</p><p>{room.description}</p><p>Facilities: {room.facilities.join(', ') || 'Not listed'}</p><div className="availability-check"><label>Start<input type="datetime-local" value={startAt} onChange={(event) => setStartAt(event.target.value)} /></label><label>End<input type="datetime-local" value={endAt} onChange={(event) => setEndAt(event.target.value)} /></label><button className="button-secondary" onClick={checkAvailability}>Check availability</button>{availability !== null && <span>{availability ? 'Available' : 'Unavailable'}</span>}</div><Link className="button-primary" to="/reservations/new">Request a time</Link></>;
}