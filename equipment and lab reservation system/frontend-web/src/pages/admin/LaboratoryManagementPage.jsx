import LaboratoryForm from '../../components/forms/LaboratoryForm.jsx';
import { useCallback, useEffect, useState } from 'react';
import { laboratoryService } from '../../services/laboratoryService.js';

export default function LaboratoryManagementPage() {
  const [rooms, setRooms] = useState([]);
  const [editing, setEditing] = useState(null);
  const [blockRoom, setBlockRoom] = useState(null);
  const [error, setError] = useState('');
  const load = useCallback(async () => {
    try {
      const { data } = await laboratoryService.list();
      setRooms(data.results ?? data);
      setError('');
    } catch {
      setError('Administrator access is required to manage laboratories.');
    }
  }, []);
  useEffect(() => { load(); }, [load]);

  async function save(values) {
    try {
      if (editing) await laboratoryService.update(editing.id, values);
      else await laboratoryService.create(values);
      setEditing(null);
      await load();
    } catch {
      setError('Laboratory could not be saved. Check the room number and permissions.');
    }
  }

  async function block(event) {
    event.preventDefault();
    const values = Object.fromEntries(new FormData(event.currentTarget));
    try {
      await laboratoryService.block(blockRoom.id, {
        start_at: new Date(values.start_at).toISOString(),
        end_at: new Date(values.end_at).toISOString(),
        reason: values.reason,
      });
      setBlockRoom(null);
    } catch {
      setError('Room block could not be saved.');
    }
  }

  return <><p className="eyebrow">ADMINISTRATION</p><h1>Laboratories</h1><p className="welcome-copy">Maintain capacity, facilities, operating hours and room status.</p>{error && <p className="form-error" role="alert">{error}</p>}<LaboratoryForm key={editing?.id ?? 'new'} initialValue={editing || {}} onSubmit={save} />{editing && <button className="text-button" onClick={() => setEditing(null)}>Cancel edit</button>}{blockRoom && <form className="data-form" onSubmit={block}><h2>Block {blockRoom.name}</h2><label>Start<input name="start_at" type="datetime-local" required /></label><label>End<input name="end_at" type="datetime-local" required /></label><label>Reason<input name="reason" required placeholder="Maintenance or school event" /></label><button className="button-primary">Save block</button><button type="button" className="button-secondary" onClick={() => setBlockRoom(null)}>Cancel</button></form>}<section className="catalog-list">{rooms.map((room) => <article className="catalog-row" key={room.id}><div className="item-symbol">L</div><div className="item-details"><strong>{room.name} · {room.building} {room.room_number}</strong><span>{room.capacity} seats · {room.facilities.join(', ') || 'No facilities listed'} · {room.opening_time?.slice(0, 5) || 'Hours unset'}–{room.closing_time?.slice(0, 5) || 'unset'}</span></div><button className="text-button" onClick={() => setEditing(room)}>Edit</button><button className="text-button" onClick={() => setBlockRoom(room)}>Block time</button><button className="text-button" onClick={async () => { await laboratoryService.archive(room.id); await load(); }}>Archive</button></article>)}</section></>;
}