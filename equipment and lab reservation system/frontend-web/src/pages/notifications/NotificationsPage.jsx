import { useCallback, useEffect, useState } from 'react';
import { notificationService } from '../../services/notificationService.js';

export default function NotificationsPage() {
  const [items, setItems] = useState([]);
  const [error, setError] = useState('');
  const load = useCallback(async () => {
    try {
      const { data } = await notificationService.list();
      setItems(data.results ?? data);
    } catch {
      setError('Notifications could not be loaded.');
    }
  }, []);
  useEffect(() => { load(); }, [load]);
  async function markRead(id) {
    await notificationService.markRead(id);
    await load();
  }
  return <><p className="eyebrow">YOUR INBOX</p><h1>Notifications</h1><p className="welcome-copy">Reservation decisions and due-date reminders.</p>{error && <p className="form-error" role="alert">{error}</p>}<section className="catalog-list">{items.length === 0 && !error && <p className="empty-panel">You are all caught up.</p>}{items.map((item) => <article className="catalog-row" key={item.id}><div className="item-details"><strong>{item.title}</strong><span>{item.message} · {new Date(item.created_at).toLocaleString()}</span></div>{item.read_at ? <span className="status status-approved">Read</span> : <button className="text-button" onClick={() => markRead(item.id)}>Mark read</button>}</article>)}</section></>;
}