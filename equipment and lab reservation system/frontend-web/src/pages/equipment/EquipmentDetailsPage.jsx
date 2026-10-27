import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { equipmentService } from '../../services/equipmentService.js';

export default function EquipmentDetailsPage() {
  const { id } = useParams();
  const [item, setItem] = useState(null);
  const [error, setError] = useState('');
  useEffect(() => { equipmentService.get(id).then(({ data }) => setItem(data)).catch(() => setError('Equipment details could not be loaded.')); }, [id]);
  if (error) return <p className="form-error" role="alert">{error}</p>;
  if (!item) return <p>Loading equipment…</p>;
  return <><p className="eyebrow">EQUIPMENT DETAILS · {item.asset_tag}</p><h1>{item.name}</h1><p className="welcome-copy">{item.description}</p><dl className="detail-list"><dt>Category</dt><dd>{item.category}</dd><dt>Condition</dt><dd>{item.condition}</dd><dt>Available</dt><dd>{item.available_quantity ?? item.quantity} of {item.quantity}</dd><dt>Location</dt><dd>{item.location || 'Not set'}</dd></dl>{item.image && <img className="resource-image" src={item.image} alt={item.name} />}<Link className="button-primary" to="/reservations/new">Request a reservation</Link></>;
}