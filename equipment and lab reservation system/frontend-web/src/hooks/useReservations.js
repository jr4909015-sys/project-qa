import { useEffect, useState } from 'react';
import { reservationService } from '../services/reservationService.js';

export function useReservations(params) {
  const [state, setState] = useState({ data: [], loading: true, error: null });
  useEffect(() => {
    let active = true;
    reservationService.list(params)
      .then(({ data }) => { if (active) setState({ data: data.results ?? data, loading: false, error: null }); })
      .catch((error) => { if (active) setState({ data: [], loading: false, error }); });
    return () => { active = false; };
  }, [params]);
  return state;
}