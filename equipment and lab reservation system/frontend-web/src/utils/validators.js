export function isSchoolEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

export function requiredText(value) {
  return typeof value === 'string' && value.trim().length > 0;
}