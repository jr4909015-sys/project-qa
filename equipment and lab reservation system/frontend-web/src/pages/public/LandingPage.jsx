import { Link } from 'react-router-dom';

export default function LandingPage() {
  return <main className="landing-page"><header className="landing-nav"><span className="brand-mark">S</span><span>Campus Reserve</span><Link to="/login">Sign in</Link></header><section className="landing-content"><p className="eyebrow">NORTH CAMPUS · RESOURCE DESK</p><h1>Tools, spaces,<br /><em>ready when you are.</em></h1><p>One place to find school equipment and book the laboratories that help your next idea take shape.</p><Link className="button-primary" to="/login">Open student portal</Link></section></main>;
}