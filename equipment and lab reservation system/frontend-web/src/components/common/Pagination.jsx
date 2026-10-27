export default function Pagination({ page, totalPages, onChange }) {
  return <nav className="pagination" aria-label="Pagination"><button disabled={page <= 1} onClick={() => onChange(page - 1)}>Previous</button><span>Page {page} of {totalPages}</span><button disabled={page >= totalPages} onClick={() => onChange(page + 1)}>Next</button></nav>;
}