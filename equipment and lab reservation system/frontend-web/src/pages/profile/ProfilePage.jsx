import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth.js';
import { authService } from '../../services/authService.js';

export default function ProfilePage() {
  const { user, refreshUser, signOut } = useAuth();
  const navigate = useNavigate();
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  async function updateProfile(event) {
    event.preventDefault();
    setSaving(true);
    try {
      const form = new FormData(event.currentTarget);
      const values = new FormData();
      for (const [key, value] of form.entries()) {
        if (key !== 'photo' || value.size > 0) values.append(key, value);
      }
      await authService.updateProfile(values);
      await refreshUser();
      setMessage('Profile updated.');
      setError('');
    } catch (requestError) {
      setError(requestError.response?.data?.detail || requestError.response?.data?.photo?.[0] || 'Profile could not be updated.');
    } finally {
      setSaving(false);
    }
  }
  async function changePassword(event) {
    event.preventDefault();
    setSaving(true);
    try {
      const values = Object.fromEntries(new FormData(event.currentTarget));
      await authService.changePassword(values);
      event.currentTarget.reset();
      setMessage('Password updated.');
      setError('');
    } catch (requestError) {
      setError(requestError.response?.data?.new_password?.[0] || requestError.response?.data?.old_password?.[0] || 'Password could not be updated.');
    } finally {
      setSaving(false);
    }
  }
  return <><p className="eyebrow">YOUR ACCOUNT · {user?.role}</p><div className="welcome-row"><div><h1>Profile</h1></div><button className="button-secondary" onClick={() => { signOut(); navigate('/login', { replace: true }); }}>Sign out</button></div>{message && <p className="success-message" role="status">{message}</p>}{error && <p className="form-error" role="alert">{error}</p>}<form className="data-form" onSubmit={updateProfile}><label>Profile photo{user?.photo && <img className="profile-photo" src={user.photo} alt="Current profile" />}<input name="photo" type="file" accept="image/*" /></label><label>Username<input value={user?.username || ''} readOnly /></label><div className="form-pair"><label>First name<input name="first_name" defaultValue={user?.first_name} /></label><label>Last name<input name="last_name" defaultValue={user?.last_name} /></label></div><label>School email<input name="email" type="email" defaultValue={user?.email} /></label><div className="form-pair"><label>Student or employee ID<input name="student_employee_id" defaultValue={user?.student_employee_id} /></label><label>Department<input name="department" defaultValue={user?.department} /></label></div><label>Contact number<input name="contact_number" type="tel" defaultValue={user?.contact_number} /></label><button className="button-primary" disabled={saving}>{saving ? 'Saving...' : 'Save profile'}</button></form><form className="data-form" onSubmit={changePassword}><h2>Change password</h2><label>Current password<input name="old_password" type="password" required autoComplete="current-password" /></label><label>New password<input name="new_password" type="password" minLength="10" required autoComplete="new-password" /></label><button className="button-secondary" disabled={saving}>{saving ? 'Saving...' : 'Update password'}</button></form></>;
}