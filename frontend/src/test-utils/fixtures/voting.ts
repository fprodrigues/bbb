import type {
  Election,
  HourlyResponse,
  Participant,
  PastElection,
  ResultsResponse,
} from '@/types/voting';

export const participants: Participant[] = [
  { id: 1, name: 'Ana Silva', avatar_url: null, active: true },
  { id: 2, name: 'Bruno Costa', avatar_url: null, active: true },
  { id: 3, name: 'Carla Mendes', avatar_url: null, active: true },
];

export const draftElection: Election = {
  id: 10,
  status: 'draft',
  started_at: null,
  ended_at: null,
  participants: [participants[0], participants[1]],
};

export const runningElection: Election = {
  id: 11,
  status: 'running',
  started_at: '2026-07-06T12:00:00.000Z',
  ended_at: null,
  participants: [participants[0], participants[1]],
};

export const closedElection: Election = {
  id: 12,
  status: 'closed',
  started_at: '2026-07-05T12:00:00.000Z',
  ended_at: '2026-07-05T18:00:00.000Z',
  participants: [participants[0], participants[1]],
};

export const results: ResultsResponse = {
  election_id: runningElection.id,
  status: 'running',
  total_votes: 150,
  candidates: [
    {
      participant_id: 1,
      name: 'Ana Silva',
      votes: 90,
      percentage: 60,
    },
    {
      participant_id: 2,
      name: 'Bruno Costa',
      votes: 60,
      percentage: 40,
    },
  ],
};

export const updatedResultsAfterVote: ResultsResponse = {
  election_id: runningElection.id,
  status: 'running',
  total_votes: 151,
  candidates: [
    {
      participant_id: 1,
      name: 'Ana Silva',
      votes: 91,
      percentage: 60.26,
    },
    {
      participant_id: 2,
      name: 'Bruno Costa',
      votes: 60,
      percentage: 39.74,
    },
  ],
};

export const hourlyResults: HourlyResponse = {
  election_id: runningElection.id,
  hours: [
    { hour: '2026-07-06T12:00:00.000Z', total_votes: 40 },
    { hour: '2026-07-06T13:00:00.000Z', total_votes: 55 },
    { hour: '2026-07-06T14:00:00.000Z', total_votes: 55 },
  ],
};

export const pastElections: PastElection[] = [
  {
    id: 5,
    status: 'closed',
    started_at: '2026-06-01T10:00:00.000Z',
    ended_at: '2026-06-01T22:00:00.000Z',
    total_votes: 320,
    participants: [
      {
        participant_id: 1,
        name: 'Ana Silva',
        votes: 200,
        percentage: 62.5,
      },
      {
        participant_id: 2,
        name: 'Bruno Costa',
        votes: 120,
        percentage: 37.5,
      },
    ],
  },
];
