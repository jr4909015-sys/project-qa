import { useCallback, useEffect, useState } from 'react';
import { equipmentService } from '../../services/equipmentService.js';

export default function EquipmentLoansPage() {
  const [loans, setLoans] = useState([]);
  const [equipment, setEquipment] = useState([]);
  const [error, setError] = useState('');
  const load = useCallback(async () => {
    try {
      const [loanResponse, equipmentResponse] = await Promise.all([equipmentService.loans(), equipmentService.list()]);
      setLoans(loanResponse.data.results ?? loanResponse.data);
      setEquipment(equipmentResponse.data.results ?? equipmentResponse.data);
    } catch {
      setError('Staff access is required to manage check-outs and returns.');
    }
  }, []);
  useEffect(() => { load(); }, [load]);

  async function checkOut(event) {
    event.preventDefault();
    const values = Object.fromEntries(new FormData(event.currentTarget));
    values.equipment = Number(values.equipment);
    values.borrower = Number(values.borrower);
    values.quantity = Number(values.quantity);
    values.due_at = new Date(values.due_at).toISOString();
    values.reservation = values.reservation ? Number(values.reservation) : null;
    try {
      await equipmentService.checkOut(values);
      event.currentTarget.reset();
      await load();
      setError('');
    } catch (requestError) {
      setError(requestError.response?.data?.quantity?.[0] || 'Check-out could not be recorded.');
    }
  }

  async function returnLoan(id, condition) {
    try {
      await equipmentService.returnItem(id, condition);
      await load();
      setError('');
    } catch {
      setError('Return could not be recorded.');
    }
  }

  return <><p className="eyebrow">EQUIPMENT DESK</p><h1>Check-out and returns</h1><p className="welcome-copy">Record custody, due dates and returned condition.</p>{error && <p className="form-error" role="alert">{error}</p>}<form className="data-form" onSubmit={checkOut}><h2>Check out equipment</h2><label>Equipment<select name="equipment" required defaultValue=""><option value="" disabled>Select item</option>{equipment.map((item) => <option key={item.id} value={item.id}>{item.name} · {item.available_quantity ?? item.quantity} available</option>)}</select></label><div className="form-pair"><label>Borrower user ID<input name="borrower" type="number" min="1" required /></label><label>Quantity<input name="quantity" type="number" min="1" defaultValue="1" required /></label></div><label>Due date and time<input name="due_at" type="datetime-local" required /></label><label>Reservation ID (optional)<input name="reservation" type="number" min="1" /></label><button className="button-primary">Record check-out</button></form><section className="catalog-list">{loans.map((loan) => <article className="catalog-row" key={loan.id}><div className="item-details"><strong>{loan.equipment_name} · {loan.quantity} units</strong><span>Borrower {loan.borrower} · Due {new Date(loan.due_at).toLocaleString()}</span></div><span className={`status ${loan.returned_at ? 'status-approved' : loan.is_overdue ? 'status-pending' : 'status-approved'}`}>{loan.returned_at ? `Returned · ${loan.return_condition}` : loan.is_overdue ? 'Overdue' : 'Checked out'}</span>{!loan.returned_at && <select aria-label={`Return condition for loan ${loan.id}`} defaultValue="good" onChange={(event) => returnLoan(loan.id, event.target.value)}><option value="good">Return: good</option><option value="fair">Return: fair</option><option value="damaged">Return: damaged</option><option value="maintenance">Return: maintenance</option></select>}</article>)}</section></>;
}