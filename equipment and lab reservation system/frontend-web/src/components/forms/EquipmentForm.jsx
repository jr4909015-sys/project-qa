export default function EquipmentForm({ initialValue = {}, onSubmit }) {
  function submit(event) {
    event.preventDefault();
    const values = new FormData(event.currentTarget);
    if (!values.get('image')?.size) values.delete('image');
    onSubmit?.(values);
  }
  return <form className="data-form" onSubmit={submit}><label>Equipment name<input name="name" required defaultValue={initialValue.name} /></label><label>Category<input name="category" required defaultValue={initialValue.category} /></label><label>Asset tag<input name="asset_tag" required defaultValue={initialValue.asset_tag} /></label><label>Description<textarea name="description" rows="2" defaultValue={initialValue.description} /></label><label>Location<input name="location" defaultValue={initialValue.location} /></label><label>Total units<input name="quantity" type="number" min="1" defaultValue={initialValue.quantity ?? 1} /></label><label>Condition<select name="condition" defaultValue={initialValue.condition ?? 'good'}><option value="good">Good</option><option value="fair">Fair</option><option value="damaged">Damaged</option><option value="maintenance">Under maintenance</option></select></label><label>Image<input name="image" type="file" accept="image/*" /></label><button className="button-primary">Save equipment</button></form>;
}