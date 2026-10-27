export default function StatCard({ label, value, note, tone = 'green' }) {
  return <article className={`stat-card tone-${tone}`}><div className="stat-label">{label}</div><strong>{value}</strong><div className="stat-note">{note}</div></article>;
}