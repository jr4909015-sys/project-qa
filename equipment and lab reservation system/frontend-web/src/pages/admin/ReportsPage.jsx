import { useState } from 'react';
import { reportService } from '../../services/reportService.js';

export default function ReportsPage() {
  const [report, setReport] = useState(null);
  const [error, setError] = useState('');
  const [filters, setFilters] = useState({ start: '', end: '' });
  async function load(event) {
    event?.preventDefault();
    try {
      const { data } = await reportService.reservations(filters);
      setReport(data);
      setError('');
    } catch {
      setError('Administrator access is required to view reports.');
    }
  }
  async function download(format) {
    try {
      const response = await reportService.exportReservations(filters, format);
      const url = URL.createObjectURL(response.data);
      const link = document.createElement('a');
      link.href = url;
      link.download = `reservation-report.${format}`;
      link.click();
      URL.revokeObjectURL(url);
    } catch {
      setError('Report export failed.');
    }
  }
  return <><p className="eyebrow">ADMINISTRATION</p><div className="welcome-row"><div><h1>Reports</h1><p className="welcome-copy">Reservation history and resource utilization.</p></div><div className="report-export-actions"><button className="button-secondary" onClick={() => download('csv')}>Export CSV</button><button className="button-secondary" onClick={() => download('xlsx')}>Export Excel</button></div></div><form className="report-filters" onSubmit={load}><label>From<input type="date" value={filters.start} onChange={(event) => setFilters((value) => ({ ...value, start: event.target.value }))} /></label><label>To<input type="date" value={filters.end} onChange={(event) => setFilters((value) => ({ ...value, end: event.target.value }))} /></label><button className="button-primary">Run report</button></form>{error && <p className="form-error" role="alert">{error}</p>}{report && <div className="report-grid"><section className="catalog-list"><h2>Reservations by status · {report.total}</h2>{report.by_status.map((row) => <div className="reservation-row" key={row.status}><strong>{row.status}</strong><span>{row.count}</span></div>)}</section><section className="catalog-list"><h2>Most borrowed equipment</h2>{report.top_equipment.map((row) => <div className="reservation-row" key={row.equipment__name}><strong>{row.equipment__name}</strong><span>{row.borrowed} units</span></div>)}</section><section className="catalog-list"><h2>Laboratory usage</h2>{report.laboratory_usage.map((row) => <div className="reservation-row" key={row.laboratory__name}><strong>{row.laboratory__name}</strong><span>{row.bookings} bookings</span></div>)}</section></div>}</>;
}