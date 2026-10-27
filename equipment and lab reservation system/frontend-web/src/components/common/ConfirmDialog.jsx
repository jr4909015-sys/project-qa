export default function ConfirmDialog({ open, title, children, onConfirm, onCancel }) {
  if (!open) return null;
  return <div className="dialog-backdrop" role="presentation"><section className="dialog" role="alertdialog" aria-modal="true" aria-labelledby="dialog-title"><h2 id="dialog-title">{title}</h2><div>{children}</div><div className="dialog-actions"><button onClick={onCancel}>Cancel</button><button className="button-primary" onClick={onConfirm}>Confirm</button></div></section></div>;
}