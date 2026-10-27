import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { authService } from '../../services/authService.js';

export default function RegisterPage() {
  const [error, setError] = useState('');
  const navigate = useNavigate();
  async function submit(event) {
    event.preventDefault();
    const values = Object.fromEntries(new FormData(event.currentTarget));
    try {
      await authService.register(values);
      navigate('/login', { state: { registered: true } });
    } catch (requestError) {
      setError(requestError.response?.data?.username?.[0] || requestError.response?.data?.email?.[0] || 'Account could not be created.');
    }
  }
  return <main className="login-page"><form className="login-form" onSubmit={submit}><span className="brand-mark">S</span><p className="eyebrow">CREATE ACCOUNT</p><h1>Join your campus.</h1><label>Username<input name="username" required autoComplete="username" /></label><div className="form-pair"><label>First name<input name="first_name" required /></label><label>Last name<input name="last_name" required /></label></div><label>School email<input name="email" type="email" required /></label><label>Password<input name="password" type="password" minLength="10" required autoComplete="new-password" /></label>{error && <p className="form-error" role="alert">{error}</p>}<button className="button-primary">Create account</button><small>Already registered? <Link to="/login">Sign in</Link></small></form></main>;
}