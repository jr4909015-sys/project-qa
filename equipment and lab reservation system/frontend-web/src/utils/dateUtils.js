export function formatDateTime(value, locale = undefined) {
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
  return new Intl.DateTimeFormat(locale, { dateStyle: 'medium', timeStyle: 'short' }).format(date);
}

export function isValidReservationRange(start, end) {
  const startDate = new Date(start);
  const endDate = new Date(end);
  return Number.isFinite(startDate.getTime()) && Number.isFinite(endDate.getTime()) && endDate > startDate;
}