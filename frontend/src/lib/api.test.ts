import { api } from './api';

const API_URL = 'http://localhost:3001';

function mockFetchJson(
  data: unknown,
  options: { ok?: boolean; status?: number } = {},
) {
  const { ok = true, status = 200 } = options;

  return jest.fn().mockResolvedValue({
    ok,
    status,
    json: jest.fn().mockResolvedValue(data),
  });
}

function mockFetchError(status: number, payload?: Record<string, string>) {
  return jest.fn().mockResolvedValue({
    ok: false,
    status,
    json: jest.fn().mockResolvedValue(payload ?? {}),
  });
}

describe('api', () => {
  const originalFetch = global.fetch;

  beforeEach(() => {
    global.fetch = jest.fn();
  });

  afterEach(() => {
    global.fetch = originalFetch;
    jest.clearAllMocks();
  });

  it('getParticipants faz GET na rota correta', async () => {
    const participants = [{ id: 1, name: 'Ana' }];
    (global.fetch as jest.Mock).mockImplementation(
      mockFetchJson(participants),
    );

    const result = await api.getParticipants();

    expect(global.fetch).toHaveBeenCalledWith(
      `${API_URL}/api/participants`,
      expect.objectContaining({
        headers: expect.objectContaining({
          'Content-Type': 'application/json',
        }),
        cache: 'no-store',
      }),
    );
    expect(result).toEqual(participants);
  });

  it('getCurrentElection faz GET na rota correta', async () => {
    const election = { id: 1, status: 'draft', participants: [] };
    (global.fetch as jest.Mock).mockImplementation(mockFetchJson(election));

    const result = await api.getCurrentElection();

    expect(global.fetch).toHaveBeenCalledWith(
      `${API_URL}/api/elections/current`,
      expect.any(Object),
    );
    expect(result).toEqual(election);
  });

  it('createElection envia POST com body correto', async () => {
    const election = { id: 2, status: 'draft', participants: [] };
    (global.fetch as jest.Mock).mockImplementation(mockFetchJson(election));

    const result = await api.createElection([1, 2]);

    expect(global.fetch).toHaveBeenCalledWith(
      `${API_URL}/api/admin/elections`,
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ participant_ids: [1, 2] }),
        headers: expect.objectContaining({
          'Content-Type': 'application/json',
        }),
      }),
    );
    expect(result).toEqual(election);
  });

  it('startElection envia POST na rota correta', async () => {
    const election = { id: 3, status: 'running', participants: [] };
    (global.fetch as jest.Mock).mockImplementation(mockFetchJson(election));

    const result = await api.startElection(3);

    expect(global.fetch).toHaveBeenCalledWith(
      `${API_URL}/api/admin/elections/3/start`,
      expect.objectContaining({ method: 'POST' }),
    );
    expect(result).toEqual(election);
  });

  it('closeElection envia POST na rota correta', async () => {
    const election = { id: 4, status: 'closed', participants: [] };
    (global.fetch as jest.Mock).mockImplementation(mockFetchJson(election));

    const result = await api.closeElection(4);

    expect(global.fetch).toHaveBeenCalledWith(
      `${API_URL}/api/admin/elections/4/close`,
      expect.objectContaining({ method: 'POST' }),
    );
    expect(result).toEqual(election);
  });

  it('vote envia POST com participant_id no body', async () => {
    const results = {
      election_id: 1,
      status: 'running',
      total_votes: 10,
      candidates: [],
    };
    (global.fetch as jest.Mock).mockImplementation(mockFetchJson(results));

    const result = await api.vote(7);

    expect(global.fetch).toHaveBeenCalledWith(
      `${API_URL}/api/votes`,
      expect.objectContaining({
        method: 'POST',
        body: JSON.stringify({ participant_id: 7 }),
      }),
    );
    expect(result).toEqual(results);
  });

  it('getResults faz GET na rota correta', async () => {
    const results = {
      election_id: 1,
      status: 'running',
      total_votes: 0,
      candidates: [],
    };
    (global.fetch as jest.Mock).mockImplementation(mockFetchJson(results));

    const result = await api.getResults();

    expect(global.fetch).toHaveBeenCalledWith(
      `${API_URL}/api/elections/current/results`,
      expect.any(Object),
    );
    expect(result).toEqual(results);
  });

  it('getHourlyResults faz GET na rota correta', async () => {
    const hourly = { election_id: 1, hours: [] };
    (global.fetch as jest.Mock).mockImplementation(mockFetchJson(hourly));

    const result = await api.getHourlyResults();

    expect(global.fetch).toHaveBeenCalledWith(
      `${API_URL}/api/elections/current/hourly`,
      expect.any(Object),
    );
    expect(result).toEqual(hourly);
  });

  it('getPastElections faz GET na rota correta', async () => {
    const history: unknown[] = [];
    (global.fetch as jest.Mock).mockImplementation(mockFetchJson(history));

    const result = await api.getPastElections();

    expect(global.fetch).toHaveBeenCalledWith(
      `${API_URL}/api/admin/elections/history`,
      expect.any(Object),
    );
    expect(result).toEqual(history);
  });

  it('lança erro com mensagem padrão quando response.ok é false', async () => {
    (global.fetch as jest.Mock).mockImplementation(mockFetchError(500));

    await expect(api.getParticipants()).rejects.toThrow('Erro HTTP 500');
  });

  it('usa campo error do payload quando disponível', async () => {
    (global.fetch as jest.Mock).mockImplementation(
      mockFetchError(400, { error: 'Participantes inválidos' }),
    );

    await expect(api.createElection([1])).rejects.toThrow('Participantes inválidos');
  });

  it('usa campo message do payload quando error não existe', async () => {
    (global.fetch as jest.Mock).mockImplementation(
      mockFetchError(403, { message: 'Acesso negado' }),
    );

    await expect(api.getPastElections()).rejects.toThrow('Acesso negado');
  });
});
