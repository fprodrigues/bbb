export type Participant = {
  id: number;
  name: string;
  avatar_url?: string | null;
  active?: boolean;
};

export type ElectionStatus = 'draft' | 'running' | 'closed';

export type Election = {
  id: number;
  status: ElectionStatus;
  started_at?: string | null;
  ended_at?: string | null;
  participants: Participant[];
};

export type CandidateResult = {
  participant_id: number;
  name: string;
  votes: number;
  percentage: number;
};

export type ResultsResponse = {
  election_id: number | null;
  status: ElectionStatus | 'none';
  total_votes: number;
  candidates: CandidateResult[];
};

export type HourlyVote = {
  hour: string;
  total_votes: number;
};

export type HourlyResponse = {
  election_id: number | null;
  hours: HourlyVote[];
};

export type PastElection = {
  id: number;
  status: ElectionStatus;
  started_at: string;
  ended_at: string;
  total_votes: number;
  participants: CandidateResult[];
};