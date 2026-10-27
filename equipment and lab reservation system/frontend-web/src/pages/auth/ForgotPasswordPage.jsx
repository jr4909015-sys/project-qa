import { useState } from 'react';
import { Link } from 'react-router-dom';
import { authService } from '../../services/authService.js';

export default function ForgotPasswordPage() {
  const [sent, setSent] = useState(false);
  const [error, setError] = useState('');
  async function submit(event) {
    event.preventDefault();
    try {
      await authService.requestPasswordReset(new FormData(event.currentTarget).get('email'));
      setSent(true);
    } catch {
      setError('The reset request could not be sent.');
    }
  }
  return <main className="login-page"><form className="login-form" onSubmit={submit}><p className="eyebrow">ACCOUNT RECOVERY</p><h1>Reset your password.</h1><p className="welcome-copy">Enter your school email and we will send a recovery link if the account exists.</p><label>School email<input name="email" type="email" required /></label>{sent && <p className="success-message">If the account exists, a reset link has been sent.</p>}{error && <p className="form-error" role="alert">{error}</p>}<button className="button-primary">Send recovery link</button><Link to="/login">Back to sign in</Link></form></main>;
}