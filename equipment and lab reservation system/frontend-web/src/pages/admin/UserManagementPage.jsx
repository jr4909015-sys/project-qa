import { useCallback, useEffect, useMemo, useState } from 'react';
import { useAuth } from '../../hooks/useAuth.js';
import { userService } from '../../services/userService.js';

function getErrorMessage(error, fallback) {
  const data = error.response?.data;
  if (typeof data?.detail === 'string') return data.detail;
  const fieldError = Object.values(data ?? {}).find((value) => typeof value === 'string' || Array.isArray(value));
  return Array.isArray(fieldError) ? fieldError[0] : fieldError || fallback;
}

export default function UserManagementPage() {
  const { user: currentUser } = useAuth();
  const [users, setUsers] = useState([]);
  const [editing, setEditing] = useState(null);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [updatingId, setUpdatingId] = useState(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const { data } = await userService.list();
      setUsers(data.results ?? data);
    } catch {
      setError('Unable to load user accounts. Administrator access is required.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const filteredUsers = useMemo(() => {
    const query = search.trim().toLocaleLowerCase();
    return users.filter((item) => {
      const matchesQuery = !query || [
        item.username,
        item.email,
        item.first_name,
        item.last_name,
        item.role_name,
      ].some((value) => value?.toLocaleLowerCase().includes(query));
      const matchesStatus = statusFilter === 'all'
        || (statusFilter === 'active' ? item.is_active : !item.is_active);
      return matchesQuery && matchesStatus;
    });
  }, [users, search, statusFilter]);

  async function save(event) {
    event.preventDefault();
    const form = event.currentTarget;
    const values = Object.fromEntries(new FormData(form));
    if (!values.password) delete values.password;
    values.is_active = values.is_active === 'on';
    if (editing?.id === currentUser?.id) {
      values.is_active = true;
      values.role = currentUser.role;
    }
    setSaving(true);
    setError('');
    setNotice('');
    try {
      if (editing) await userService.update(editing.id, values);
      else await userService.create(values);
      setNotice(editing ? 'Account updated.' : 'Account created.');
      setEditing(null);
      form.reset();
      await load();
    } catch (saveError) {
      setError(getErrorMessage(saveError, 'User could not be saved.'));
    } finally {
      setSaving(false);
    }
  }

  async function toggleActive(item) {
    setUpdatingId(item.id);
    setError('');
    setNotice('');
    try {
      await userService.update(item.id, { is_active: !item.is_active });
      setNotice(`${item.username} ${item.is_active ? 'deactivated' : 'activated'}.`);
      await load();
    } catch (updateError) {
      setError(getErrorMessage(updateError, 'Account status could not be updated.'));
    } finally {
      setUpdatingId(null);
    }
  }

  function startEditing(item) {
    setEditing(item);
    setError('');
    setNotice('');
  }

  function cancelEditing() {
    setEditing(null);
    setError('');
  }

  const editingSelf = editing?.id === currentUser?.id;

  return (
    <>
      <p className="eyebrow">ADMINISTRATION</p>
      <h1>User management</h1>
      <p className="welcome-copy">Create accounts, assign roles and activate or deactivate access.</p>
      {error && <p className="form-error" role="alert">{error}</p>}
      {notice && <p className="availability-note" role="status">{notice}</p>}
      <form className="data-form" key={editing?.id ?? 'new-user'} onSubmit={save}>
        <div className="form-pair">
          <label>Username<input name="username" required defaultValue={editing?.username ?? ''} /></label>
          <label>Email<input name="email" type="email" defaultValue={editing?.email ?? ''} /></label>
        </div>
        <div className="form-pair">
          <label>First name<input name="first_name" defaultValue={editing?.first_name ?? ''} /></label>
          <label>Last name<input name="last_name" defaultValue={editing?.last_name ?? ''} /></label>
        </div>
        <label>
          Role
          <select name="role" defaultValue={editing?.role_name || 'student'} disabled={editingSelf}>
            <option value="student">Student</option>
            <option value="teacher">Teacher</option>
            <option value="staff">Staff</option>
            <option value="admin">Admin</option>
          </select>
        </label>
        <label>
          Password {editing && '(leave blank to keep current)'}
          <input name="password" type="password" minLength="10" required={!editing} autoComplete="new-password" />
        </label>
        <label className="checkbox-field">
          <input name="is_active" type="checkbox" defaultChecked={editing?.is_active ?? true} disabled={editingSelf} />
          {editingSelf ? 'Your account must remain active' : 'Account active'}
        </label>
        <div className="form-actions">
          <button className="button-primary" disabled={saving}>
            {saving ? 'Saving...' : editing ? 'Save account' : 'Create account'}
          </button>
          {editing && <button type="button" className="button-secondary" onClick={cancelEditing}>Cancel</button>}
        </div>
      </form>
      <div className="catalog-search">
        <input
          type="search"
          aria-label="Search users"
          placeholder="Search by name, username, email, or role"
          value={search}
          onChange={(event) => setSearch(event.target.value)}
        />
        <select aria-label="Filter users by account status" value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
          <option value="all">All accounts</option>
          <option value="active">Active</option>
          <option value="inactive">Deactivated</option>
        </select>
      </div>
      <section className="catalog-list" aria-label="User accounts" aria-busy={loading}>
        {loading ? <p className="empty-panel">Loading user accounts...</p> : filteredUsers.length === 0 ? (
          <p className="empty-panel">{users.length ? 'No accounts match your search.' : 'No user accounts found.'}</p>
        ) : filteredUsers.map((item) => {
          const isCurrentUser = item.id === currentUser?.id;
          return (
            <article className="catalog-row" key={item.id}>
              <div className="user-badge">{item.username.slice(0, 1).toUpperCase()}</div>
              <div className="item-details">
                <strong>{`${item.first_name} ${item.last_name}`.trim() || item.username} · {item.username}</strong>
                <span>{item.email || 'No email'} · {item.role_name} · {item.is_active ? 'Active' : 'Deactivated'}</span>
              </div>
              <button type="button" className="text-button" onClick={() => startEditing(item)}>Edit</button>
              <button
                type="button"
                className="text-button"
                disabled={isCurrentUser || updatingId === item.id}
                title={isCurrentUser ? 'You cannot deactivate your own account.' : undefined}
                onClick={() => toggleActive(item)}
              >
                {updatingId === item.id ? 'Updating…' : item.is_active ? 'Deactivate' : 'Activate'}
              </button>
            </article>
          );
        })}
      </section>
    </>
  );
}
