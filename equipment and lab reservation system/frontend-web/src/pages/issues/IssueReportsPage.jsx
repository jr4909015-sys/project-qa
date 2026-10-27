import { useCallback, useEffect, useState } from 'react';
import { useAuth } from '../../hooks/useAuth.js';
import { equipmentService } from '../../services/equipmentService.js';
import { issueService } from '../../services/issueService.js';
import { laboratoryService } from '../../services/laboratoryService.js';

export default function IssueReportsPage() {
  const { user } = useAuth();
  const isStaff = ['admin', 'staff'].includes(user?.role);
  const [reports, setReports] = useState([]);
  const [equipment, setEquipment] = useState([]);
  const [laboratories, setLaboratories] = useState([]);
  const [resourceType, setResourceType] = useState('equipment');
  const [error, setError] = useState('');
  const [savingId, setSavingId] = useState(null);

  const load = useCallback(async () => {
    try {
      const [issueResponse, equipmentResponse, laboratoryResponse] = await Promise.all([
        issueService.list(),
        equipmentService.list(),
        laboratoryService.list(),
      ]);
      setReports(issueResponse.data.results ?? issueResponse.data);
      setEquipment(equipmentResponse.data.results ?? equipmentResponse.data);
      setLaboratories(laboratoryResponse.data.results ?? laboratoryResponse.data);
      setError('');
    } catch {
      setError('Problem reports or resource lists could not be loaded.');
    }
  }, []);
  useEffect(() => { load(); }, [load]);

  async function submit(event) {
    event.preventDefault();
    setSavingId('new');
    try {
      await issueService.create(new FormData(event.currentTarget));
      event.currentTarget.reset();
      await load();
    } catch (requestError) {
      setError(requestError.response?.data?.description?.[0] || requestError.response?.data?.detail || 'Problem report could not be submitted.');
    } finally {
      setSavingId(null);
    }
  }

  async function update(report, event) {
    event.preventDefault();
    setSavingId(report.id);
    const form = new FormData(event.currentTarget);
    try {
      await issueService.update(report.id, {
        status: form.get('status'),
        resolution_note: form.get('resolution_note'),
      });
      await load();
    } catch (requestError) {
      setError(requestError.response?.data?.detail || 'Problem report could not be updated.');
    } finally {
      setSavingId(null);
    }
  }

  return <>
    <p className="eyebrow">RESOURCE SUPPORT</p>
    <h1>{isStaff ? 'Resource problem reports' : 'Report damage or a problem'}</h1>
    <p className="welcome-copy">Report damaged equipment, missing accessories, or a laboratory issue. Reports are shared with authorized staff.</p>
    {error && <p className="form-error" role="alert">{error}</p>}
    {!isStaff && <form className="data-form" onSubmit={submit}>
      <label>Resource type<select value={resourceType} onChange={(event) => setResourceType(event.target.value)}><option value="equipment">Equipment</option><option value="laboratory">Laboratory</option></select></label>
      <label>{resourceType === 'equipment' ? 'Equipment' : 'Laboratory'}<select name={resourceType} required defaultValue=""><option value="" disabled>Choose a resource</option>{(resourceType === 'equipment' ? equipment : laboratories).map((item) => <option value={item.id} key={item.id}>{item.name}</option>)}</select></label>
      <label>Description<textarea name="description" rows="4" maxLength="2000" required placeholder="Describe damage, missing accessories, or the issue" /></label>
      <label>Photo (optional)<input name="photo" type="file" accept="image/*" /></label>
      <button className="button-primary" disabled={savingId === 'new'}>{savingId === 'new' ? 'Submitting...' : 'Submit report'}</button>
    </form>}
    <section className="catalog-list">
      {reports.length === 0 && <p className="empty-panel">No resource problem reports.</p>}
      {reports.map((report) => <article className="approval-row" key={report.id}>
        <div>
          <p className="eyebrow">Issue #{report.id} · {report.reporter_name}</p>
          <strong>{report.equipment_name || report.laboratory_name}</strong>
          <span>{report.description}</span>
          <span>Submitted {new Date(report.created_at).toLocaleString()} · {report.status.replace('_', ' ')}</span>
          {report.photo && <a href={report.photo} target="_blank" rel="noreferrer">View attached photo</a>}
          {report.resolution_note && <span>Update: {report.resolution_note}</span>}
        </div>
        {isStaff && <form className="issue-review-form" onSubmit={(event) => update(report, event)}>
          <label>Status<select name="status" defaultValue={report.status}><option value="reported">Reported</option><option value="in_progress">In progress</option><option value="resolved">Resolved</option></select></label>
          <label>Update<textarea name="resolution_note" rows="2" defaultValue={report.resolution_note} /></label>
          <button className="button-secondary" disabled={savingId === report.id}>{savingId === report.id ? 'Saving...' : 'Save update'}</button>
        </form>}
      </article>)}
    </section>
  </>;
}
