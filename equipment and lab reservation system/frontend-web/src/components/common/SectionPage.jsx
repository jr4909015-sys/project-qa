export default function SectionPage({ eyebrow, title, description }) {
  return <><p className="eyebrow">{eyebrow}</p><h1>{title}</h1><p className="welcome-copy">{description}</p><section className="empty-panel">No records to display yet.</section></>;
}