import { useCallback, useEffect, useState } from 'react';
import { laboratoryService } from '../../services/laboratoryService.js';

export default function ScheduleManagementPage() {
  const [laboratories, setLaboratories] = useState([]);
  const [blocks, setBlocks] = useState([]);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  const load = useCallback(async () => {
    setIsLoading(true);
    try {
      const { data } = await laboratoryService.list();
      const rooms = data.results ?? data;
      const roomBlocks = await Promise.all(
        rooms.map(async (room) => {
          const response = await laboratoryService.blocks(room.id);
          return response.data.map((block) => ({
            ...block,
            laboratory_name: room.name,
            laboratory_location: `${room.building} ${room.room_number}`,
          }));
        }),
      );
      setLaboratories(rooms);
      setBlocks(roomBlocks.flat().sort((a, b) => new Date(a.start_at) - new Date(b.start_at)));
      setError('');
    } catch {
      setError('Schedules could not be loaded. Confirm administrator access and try again.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function addBlock(event) {
    event.preventDefault();
    setIsSaving(true);
    setError('');
    const form = event.currentTarget;
    const values = Object.fromEntries(new FormData(form));
    try {
      await laboratoryService.block(Number(values.laboratory), {
        start_at: new Date(values.start_at).toISOString(),
        end_at: new Date(values.end_at).toISOString(),
        reason: values.reason.trim(),
      });
      form.reset();
      await load();
    } catch (requestError) {
      setError(
        requestError.response?.data?.end_at?.[0]
          || requestError.response?.data?.start_at?.[0]
          || 'The schedule block could not be saved. Check the selected dates and times.',
      );
    } finally {
      setIsSaving(false);
    }
  }

  async function removeBlock(block) {
    setError('');
    try {
      await laboratoryService.deleteBlock(block.laboratory, block.id);
      setBlocks((current) => current.filter((item) => item.id !== block.id));
    } catch {
      setError('The schedule block could not be removed.');
    }
  }

  return (
    <>
      <p className="eyebrow">ADMINISTRATION</p>
      <h1>Schedules and closures</h1>
      <p className="welcome-copy">
        Block laboratories for maintenance and school events. Manage regular
        operating hours in laboratory settings.
      </p>
      {error && <p className="form-error" role="alert">{error}</p>}

      <form className="data-form" onSubmit={addBlock}>
        <h2>Block a laboratory</h2>
        <label>
          Laboratory
          <select name="laboratory" required defaultValue="">
            <option value="" disabled>Select a laboratory</option>
            {laboratories.filter((room) => room.is_active).map((room) => (
              <option key={room.id} value={room.id}>
                {room.name} · {room.building} {room.room_number}
              </option>
            ))}
          </select>
        </label>
        <label>
          Starts
          <input name="start_at" type="datetime-local" required />
        </label>
        <label>
          Ends
          <input name="end_at" type="datetime-local" required />
        </label>
        <label>
          Reason
          <input name="reason" maxLength="240" required placeholder="Maintenance or school event" />
        </label>
        <button className="button-primary" type="submit" disabled={isSaving || laboratories.length === 0}>
          {isSaving ? 'Saving…' : 'Add schedule block'}
        </button>
      </form>

      <section className="catalog-list" aria-labelledby="blocks-heading">
        <div className="section-heading">
          <div>
            <p className="eyebrow">ROOM AVAILABILITY</p>
            <h2 id="blocks-heading">Scheduled closures</h2>
          </div>
          <button className="button-secondary" type="button" onClick={load} disabled={isLoading}>
            Refresh
          </button>
        </div>
        {isLoading ? (
          <p className="empty-panel">Loading scheduled closures…</p>
        ) : blocks.length === 0 ? (
          <p className="empty-panel">No laboratory closures are scheduled.</p>
        ) : blocks.map((block) => (
          <article className="catalog-row" key={block.id}>
            <div className="item-symbol">S</div>
            <div className="item-details">
              <strong>{block.laboratory_name} · {block.laboratory_location}</strong>
              <span>{new Date(block.start_at).toLocaleString()} – {new Date(block.end_at).toLocaleString()}</span>
              <span>{block.reason}</span>
            </div>
            <button className="text-button" type="button" onClick={() => removeBlock(block)}>
              Remove
            </button>
          </article>
        ))}
      </section>
    </>
  );
}
