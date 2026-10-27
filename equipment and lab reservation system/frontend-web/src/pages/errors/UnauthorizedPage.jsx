import { Link } from 'react-router-dom';

export default function UnauthorizedPage() {
  return <main className="empty-state"><p className="eyebrow">ACCESS RESTRICTED</p><h1>You don't have access to this page.</h1><Link to="/">Return to overview</Link></main>;
}