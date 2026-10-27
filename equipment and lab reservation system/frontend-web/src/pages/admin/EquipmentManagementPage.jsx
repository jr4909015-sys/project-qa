import EquipmentForm from '../../components/forms/EquipmentForm.jsx';
import { useCallback, useEffect, useState } from 'react';
import { equipmentService } from '../../services/equipmentService.js';

export default function EquipmentManagementPage() {
  const [items, setItems] = useState([]);
  const [editing, setEditing] = useState(null);
  const [error, setError] = useState('');
  const load = useCallback(async () => {
    try {
      const { data } = await equipmentService.list({ include_archived: true });
      setItems(data.results ?? data);
      setError('');
    } catch {
      setError('Administrator access is required to manage inventory.');
    }
  }, []);
  useEffect(() => { load(); }, [load]);

  async function save(values) {
    try {
      if (editing) await equipmentService.update(editing.id, values);
      else await equipmentService.create(values);
      setEditing(null);
      await load();
    } catch (saveError) {
      setError(saveError.response?.data?.asset_tag?.[0] || 'Equipment could not be saved. Check the asset code and permissions.');
    }
  }

  async function archive(item) {
    await equipmentService.archive(item.id);
    await load();
  }

  return <><p className="eyebrow">ADMINISTRATION</p><h1>Equipment inventory</h1><p className="welcome-copy">Maintain asset codes, condition, quantities and availability.</p>{error && <p className="form-error" role="alert">{error}</p>}<EquipmentForm key={editing?.id ?? 'new'} initialValue={editing || {}} onSubmit={save} />{editing && <button className="text-button" onClick={() => setEditing(null)}>Cancel edit</button>}<section className="catalog-list">{items.map((item) => <article className="catalog-row" key={item.id}><div className="item-symbol">E</div><div className="item-details"><strong>{item.name} · {item.asset_tag}</strong><span>{item.category} · {item.available_quantity ?? item.quantity} / {item.quantity} available · {item.condition}</span></div>{!item.is_active && <span className="status status-pending">Archived</span>}<button className="text-button" onClick={() => setEditing(item)}>Edit</button>{item.is_active && <button className="text-button" onClick={() => archive(item)}>Archive</button>}</article>)}</section></>;
}