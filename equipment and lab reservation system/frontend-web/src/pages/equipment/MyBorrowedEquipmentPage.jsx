import { useEffect, useState } from 'react';
import { equipmentService } from '../../services/equipmentService.js';

export default function MyBorrowedEquipmentPage() {
  const [loans, setLoans] = useState([]);
  const [error, setError] = useState('');
  useEffect(() => {
    equipmentService.loans().then(({ data }) => setLoans(data.results ?? data)).catch(() => setError('Loan history could not be loaded.'));
  }, []);
  return <><p className="eyebrow">CHECKED OUT TO YOU</p><h1>My borrowed equipment</h1><p className="welcome-copy">Track current items and return due dates.</p>{error && <p className="form-error" role="alert">{error}</p>}<section className="catalog-list">{loans.map((loan) => <article className="catalog-row" key={loan.id}><div className="item-symbol">E</div><div className="item-details"><strong>{loan.equipment_name || `Equipment ${loan.equipment}`}</strong><span>Quantity {loan.quantity} · Due {new Date(loan.due_at).toLocaleString()}</span></div><span className={`status ${loan.returned_at ? 'status-approved' : loan.is_overdue ? 'status-pending' : 'status-approved'}`}>{loan.returned_at ? `Returned · ${loan.return_condition}` : loan.is_overdue ? 'Overdue' : 'Borrowed'}</span></article>)}</section></>;
}