import { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { authService } from '../../services/authService.js';

export default function ResetPasswordPage() {
  const [params] = useSearchParams();
  const [error, setError] = useState('');
  const navigate = useNavigate();
  async function submit(event) {
    event.preventDefault();
    const values = Object.fromEntries(new FormData(event.currentTarget));
    if (values.new_password !== values.confirm_password) {
      setError('Passwords do not match.');
      return;
    }
    try {
      await authService.resetPassword({ uid: params.get('uid'), token: params.get('token'), new_password: values.new_password });
      navigate('/login', { replace: true });
    } catch (requestError) {
      setError(requestError.response?.data?.new_password?.[0] || requestError.response?.data?.detail || 'Reset link is invalid or expired.');
    }
  }
  return <main className="login-page"><form className="login-form" onSubmit={submit}><p className="eyebrow">ACCOUNT RECOVERY</p><h1>Choose a new password.</h1><label>New password<input name="new_password" type="password" minLength="10" required autoComplete="new-password" /></label><label>Confirm password<input name="confirm_password" type="password" minLength="10" required autoComplete="new-password" /></label>{error && <p className="form-error" role="alert">{error}</p>}<button className="button-primary">Update password</button><Link to="/login">Back to sign in</Link></form></main>;
}