import { useState } from 'react';
import { useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Search } from 'lucide-react';
import { equipmentService } from '../../services/equipmentService.js';

export default function EquipmentListPage() {
  const [query, setQuery] = useState('');
  const [category, setCategory] = useState('');
  const [condition, setCondition] = useState('');
  const [equipment, setEquipment] = useState([]);
  const [error, setError] = useState('');
  useEffect(() => {
    equipmentService.list({ search: query, category: category || undefined, condition: condition || undefined })
      .then(({ data }) => setEquipment(data.results ?? data))
      .catch(() => setError('Equipment catalogue is unavailable.'));
  }, [query, category, condition]);
  return <><p className="eyebrow">RESOURCE CATALOGUE</p><div className="welcome-row"><div><h1>Equipment</h1><p className="welcome-copy">Search by name or location, then filter category, condition, and time availability.</p></div><Link className="text-button" to="/equipment/borrowed">My loans</Link></div><div className="catalog-filters"><label className="catalog-search"><Search size={17} /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search name, asset code, or location" /></label><input aria-label="Filter by category" value={category} onChange={(event) => setCategory(event.target.value)} placeholder="Category" /><select aria-label="Filter by condition" value={condition} onChange={(event) => setCondition(event.target.value)}><option value="">All conditions</option><option value="good">Good</option><option value="fair">Fair</option><option value="damaged">Damaged</option><option value="maintenance">Under maintenance</option></select></div>{error && <p className="form-error" role="alert">{error}</p>}<section className="catalog-list">{equipment.map((item) => <article className="catalog-row" key={item.id}>{item.image && <img className="equipment-thumbnail" src={item.image} alt="" />}<div className="item-symbol">E</div><div className="item-details"><strong>{item.name}</strong><span>{item.category} · {item.location || 'Location not set'} · {item.available_quantity ?? item.quantity} available</span></div><span className={`status ${(item.available_quantity ?? item.quantity) > 0 ? 'status-approved' : 'status-pending'}`}>{item.condition}</span><Link className="text-button" to={`/equipment/${item.id}`}>Details</Link></article>)}</section></>;
}