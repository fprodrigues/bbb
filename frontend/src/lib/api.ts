import {
  Election,
  HourlyResponse,
  Participant,
  PastElection,
  ResultsResponse,
} from '@/types/voting';

const API_URL =
  process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

async function request<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
    cache: 'no-store',
  });

  if (!response.ok) {
    let message = `Erro HTTP ${response.status}`;

    try {
      const data = await response.json();
      message = data.error || data.message || message;
    } catch {
    }

    throw new Error(message);
  }

  return response.json();
}

export const api = {
  getParticipants(): Promise<Participant[]> {
    return request<Participant[]>('/api/participants');
  },

  getCurrentElection(): Promise<Election | null> {
    return request<Election | null>('/api/elections/current');
  },

  createElection(participantIds: number[]): Promise<Election> {
    return request<Election>('/api/admin/elections', {
      method: 'POST',
      body: JSON.stringify({
        participant_ids: participantIds,
      }),
    });
  },

  startElection(electionId: number): Promise<Election> {
    return request<Election>(`/api/admin/elections/${electionId}/start`, {
      method: 'POST',
    });
  },

  closeElection(electionId: number): Promise<Election> {
    return request<Election>(`/api/admin/elections/${electionId}/close`, {
      method: 'POST',
    });
  },

  vote(participantId: number): Promise<ResultsResponse> {
    return request<ResultsResponse>('/api/votes', {
      method: 'POST',
      body: JSON.stringify({
        participant_id: participantId,
      }),
    });
  },

  getResults(): Promise<ResultsResponse> {
    return request<ResultsResponse>('/api/elections/current/results');
  },

  getHourlyResults(): Promise<HourlyResponse> {
    return request<HourlyResponse>('/api/elections/current/hourly');
  },

  getPastElections(): Promise<PastElection[]> {
    return request<PastElection[]>('/api/admin/elections/history');
  },
};