import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth.js';

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { signIn } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  async function handleSubmit(event) {
    event.preventDefault();
    setError('');
    setIsSubmitting(true);
    try {
      const user = await signIn(username.trim(), password);
      const isAdmin = user.role === 'admin' || user.role === 'staff';
      navigate(isAdmin ? '/admin' : '/', { replace: true });
    } catch (requestError) {
      if (!requestError.response) {
        setError('Unable to reach the sign-in service. Check that the API is running and try again.');
      } else {
        const detail = requestError.response.data?.detail;
        setError(
          typeof detail === 'string'
            ? detail
            : 'Sign-in failed. Check your school username and password.',
        );
      }
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="login-page login-page--signin">
      <aside className="signin-aside" aria-label="Campus reservation information">
        <Link className="signin-brand" to="/landing" aria-label="North Campus home">
          <span className="brand-mark">S</span>
          <span>Campus<span className="signin-brand-light">Reserve</span></span>
        </Link>
        <div className="signin-aside-copy">
          <p className="eyebrow">NORTH CAMPUS</p>
          <h2>Make room for what matters.</h2>
          <p>One place to find the equipment and spaces that help great ideas take shape.</p>
        </div>
        <div className="signin-illustration" aria-hidden="true">
          <div className="signin-illustration-card signin-illustration-card--back">
            <span />
            <span />
            <span />
          </div>
          <div className="signin-illustration-card signin-illustration-card--front">
            <span className="signin-illustration-mark">S</span>
            <span className="signin-illustration-line" />
            <span className="signin-illustration-line signin-illustration-line--short" />
            <span className="signin-illustration-status" />
          </div>
          <span className="signin-illustration-orbit" />
        </div>
        <p className="signin-aside-footer">A better way to share campus resources.</p>
      </aside>

      <section className="signin-main" aria-labelledby="signin-title">
        <div className="signin-mobile-brand">
          <span className="brand-mark">S</span>
          <span>Campus<span className="signin-brand-light">Reserve</span></span>
        </div>
        <div className="signin-content">
          <p className="eyebrow">YOUR CAMPUS, IN REACH</p>
          <h1 id="signin-title">Welcome back</h1>
          <p className="signin-description">Sign in to manage your reservations and discover campus resources.</p>

          {location.state?.registered && (
            <p className="signin-success" role="status">Your account is ready. Sign in to continue.</p>
          )}

          <form className="signin-form" onSubmit={handleSubmit}>
            <label htmlFor="username">Username or school email</label>
            <input
              id="username"
              name="username"
              required
              value={username}
              onChange={(event) => setUsername(event.target.value)}
              autoComplete="username"
              placeholder="Enter your username or email"
            />

            <div className="signin-password-heading">
              <label htmlFor="password">Password</label>
              <Link to="/forgot-password">Forgot password?</Link>
            </div>
            <input
              id="password"
              name="password"
              type="password"
              required
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              autoComplete="current-password"
              placeholder="Enter your password"
            />

            {error && <p className="form-error" role="alert">{error}</p>}
            <button className="button-primary signin-submit" type="submit" disabled={isSubmitting}>
              {isSubmitting ? 'Signing in…' : 'Sign in'}
              {!isSubmitting && <span aria-hidden="true">→</span>}
            </button>
          </form>

          <p className="signin-register">New to CampusReserve? <Link to="/register">Create an account</Link></p>
          <p className="signin-help">Need help accessing your account? Contact your campus administrator.</p>
        </div>
        <p className="signin-legal">© {new Date().getFullYear()} North Campus <span>·</span> Equipment &amp; Lab Reservations</p>
      </section>
    </main>
  );
}