export default function LaboratoryForm({ initialValue = {}, onSubmit }) {
  function submit(event) {
    event.preventDefault();
    const values = Object.fromEntries(new FormData(event.currentTarget));
    values.facilities = String(values.facilities || '').split(',').map((item) => item.trim()).filter(Boolean);
    onSubmit?.(values);
  }
  return <form className="data-form" onSubmit={submit}><label>Laboratory name<input name="name" required defaultValue={initialValue.name} /></label><div className="form-pair"><label>Building<input name="building" required defaultValue={initialValue.building} /></label><label>Room<input name="room_number" required defaultValue={initialValue.room_number} /></label></div><label>Capacity<input name="capacity" type="number" min="1" defaultValue={initialValue.capacity ?? 1} /></label><label>Facilities (comma-separated)<textarea name="facilities" rows="2" defaultValue={initialValue.facilities?.join?.(', ') || initialValue.facilities} /></label><div className="form-pair"><label>Opens<input name="opening_time" type="time" defaultValue={initialValue.opening_time?.slice?.(0, 5)} /></label><label>Closes<input name="closing_time" type="time" defaultValue={initialValue.closing_time?.slice?.(0, 5)} /></label></div><button className="button-primary">Save laboratory</button></form>;
}