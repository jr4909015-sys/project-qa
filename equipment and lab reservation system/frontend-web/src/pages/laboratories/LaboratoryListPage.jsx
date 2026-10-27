import { useState } from 'react';
import { useEffect } from 'react';
import { Search } from 'lucide-react';
import { Link } from 'react-router-dom';
import { laboratoryService } from '../../services/laboratoryService.js';

export default function LaboratoryListPage() {
  const [query, setQuery] = useState('');
  const [building, setBuilding] = useState('');
  const [minimumCapacity, setMinimumCapacity] = useState('');
  const [laboratories, setLaboratories] = useState([]);
  const [error, setError] = useState('');
  useEffect(() => {
    laboratoryService.list({ search: query, building: building || undefined, min_capacity: minimumCapacity || undefined })
      .then(({ data }) => setLaboratories(data.results ?? data))
      .catch(() => setError('Laboratory catalogue is unavailable.'));
  }, [query, building, minimumCapacity]);
  return <><p className="eyebrow">ROOM DIRECTORY</p><div className="welcome-row"><div><h1>Laboratories</h1><p className="welcome-copy">Search by room or building, filter by capacity, and check time availability.</p></div></div><div className="catalog-filters"><label className="catalog-search"><Search size={17} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search laboratories or facilities" /></label><input aria-label="Filter by building" value={building} onChange={(event) => setBuilding(event.target.value)} placeholder="Building" /><input aria-label="Minimum laboratory capacity" type="number" min="1" value={minimumCapacity} onChange={(event) => setMinimumCapacity(event.target.value)} placeholder="Min. seats" /></div>{error && <p className="form-error" role="alert">{error}</p>}<section className="catalog-list">{laboratories.map((room) => <article className="catalog-row" key={room.id}><div className="item-symbol">L</div><div className="item-details"><strong>{room.name}</strong><span>{room.building} · {room.room_number} · {room.capacity} seats · {room.facilities.join(', ') || 'Facilities not listed'}</span></div><span className="availability-note">{room.opening_time?.slice(0, 5) || 'Hours unset'}–{room.closing_time?.slice(0, 5) || 'unset'}</span><Link className="text-button" to={`/laboratories/${room.id}`}>Availability</Link></article>)}</section></>;
}