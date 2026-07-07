import { screen, waitFor, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import AdminPage from './page';
import { renderWithTheme } from '@/test-utils/render';
import { mockApi } from '@/test-utils/mocks/api';
import {
  draftElection,
  hourlyResults,
  participants,
  pastElections,
  results,
  runningElection,
} from '@/test-utils/fixtures/voting';

jest.mock('@/lib/api');

function setupDefaultAdminMocks() {
  mockApi.getParticipants.mockResolvedValue(participants);
  mockApi.getCurrentElection.mockResolvedValue(null);
  mockApi.getPastElections.mockResolvedValue([]);
  mockApi.getResults.mockResolvedValue(results);
  mockApi.getHourlyResults.mockResolvedValue(hourlyResults);
}

async function waitForAdminLoaded() {
  await screen.findByRole('heading', { name: 'Painel Administrativo' });
}

describe('AdminPage', () => {
  beforeEach(() => {
    jest.useFakeTimers({ advanceTimers: true });
    setupDefaultAdminMocks();
  });

  afterEach(() => {
    jest.runOnlyPendingTimers();
    jest.clearAllTimers();
    jest.useRealTimers();
    jest.clearAllMocks();
  });

  it('mostra estado de loading inicialmente', () => {
    mockApi.getParticipants.mockImplementation(() => new Promise(() => {}));

    renderWithTheme(<AdminPage />);

    expect(screen.getByText('Carregando painel admin...')).toBeInTheDocument();
    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('renderiza título e aviso de admin sem autenticação', async () => {
    renderWithTheme(<AdminPage />);

    await waitForAdminLoaded();

    expect(
      screen.getByText(/este admin está sem autenticação para reduzir o escopo do teste/i),
    ).toBeInTheDocument();
  });

  it('lista participantes disponíveis para seleção', async () => {
    renderWithTheme(<AdminPage />);

    await waitForAdminLoaded();

    expect(screen.getByText('Ana Silva')).toBeInTheDocument();
    expect(screen.getByText('Bruno Costa')).toBeInTheDocument();
    expect(screen.getByText('Carla Mendes')).toBeInTheDocument();
  });

  it('permite selecionar exatamente dois participantes e bloqueia o terceiro', async () => {
    const user = userEvent.setup({ advanceTimers: jest.advanceTimersByTime });

    renderWithTheme(<AdminPage />);
    await waitForAdminLoaded();

    const createButton = screen.getByRole('button', { name: /criar votação/i });
    expect(createButton).toBeDisabled();

    const checkboxes = screen.getAllByRole('checkbox');
    await user.click(checkboxes[0]);
    await user.click(checkboxes[1]);

    expect(createButton).toBeEnabled();
    expect(checkboxes[2]).toBeDisabled();
  });

  it('cria votação com dois participantes selecionados', async () => {
    const user = userEvent.setup({ advanceTimers: jest.advanceTimersByTime });

    mockApi.createElection.mockResolvedValue(draftElection);

    renderWithTheme(<AdminPage />);
    await waitForAdminLoaded();

    const checkboxes = screen.getAllByRole('checkbox');
    await user.click(checkboxes[0]);
    await user.click(checkboxes[1]);
    await user.click(screen.getByRole('button', { name: /criar votação/i }));

    await waitFor(() => {
      expect(mockApi.createElection).toHaveBeenCalledWith([1, 2]);
    });

    expect(await screen.findByText('Votação criada com sucesso.')).toBeInTheDocument();
  });

  it('mostra status draft com botões corretos', async () => {
    mockApi.getCurrentElection.mockResolvedValue(draftElection);

    renderWithTheme(<AdminPage />);
    await waitForAdminLoaded();

    expect(screen.getByText('Criada, aguardando início')).toBeInTheDocument();

    const startButton = screen.getByRole('button', { name: /iniciar votação/i });
    const closeButton = screen.getByRole('button', { name: /encerrar votação/i });

    expect(startButton).toBeEnabled();
    expect(closeButton).toBeDisabled();
  });

  it('inicia votação com sucesso', async () => {
    const user = userEvent.setup({ advanceTimers: jest.advanceTimersByTime });

    mockApi.getCurrentElection.mockResolvedValue(draftElection);
    mockApi.startElection.mockResolvedValue(runningElection);

    renderWithTheme(<AdminPage />);
    await waitForAdminLoaded();

    await user.click(screen.getByRole('button', { name: /iniciar votação/i }));

    await waitFor(() => {
      expect(mockApi.startElection).toHaveBeenCalledWith(draftElection.id);
    });

    expect(await screen.findByText('Votação iniciada com sucesso.')).toBeInTheDocument();
  });

  it('mostra status running com botões corretos', async () => {
    mockApi.getCurrentElection.mockResolvedValue(runningElection);

    renderWithTheme(<AdminPage />);
    await waitForAdminLoaded();

    expect(screen.getByText('Em andamento')).toBeInTheDocument();

    const startButton = screen.getByRole('button', { name: /iniciar votação/i });
    const closeButton = screen.getByRole('button', { name: /encerrar votação/i });

    expect(startButton).toBeDisabled();
    expect(closeButton).toBeEnabled();
  });

  it('encerra votação com sucesso', async () => {
    const user = userEvent.setup({ advanceTimers: jest.advanceTimersByTime });

    mockApi.getCurrentElection.mockResolvedValue(runningElection);
    mockApi.closeElection.mockResolvedValue({
      ...runningElection,
      status: 'closed',
      ended_at: '2026-07-06T20:00:00.000Z',
    });

    renderWithTheme(<AdminPage />);
    await waitForAdminLoaded();

    await user.click(screen.getByRole('button', { name: /encerrar votação/i }));

    await waitFor(() => {
      expect(mockApi.closeElection).toHaveBeenCalledWith(runningElection.id);
    });

    expect(await screen.findByText('Votação encerrada com sucesso.')).toBeInTheDocument();
  });

  it('mostra cards de resumo e tabela de votos por hora', async () => {
    mockApi.getCurrentElection.mockResolvedValue(runningElection);

    renderWithTheme(<AdminPage />);
    await waitForAdminLoaded();

    expect(screen.getByText('Total geral de votos')).toBeInTheDocument();
    expect(screen.getByText('Participantes no paredão')).toBeInTheDocument();
    expect(screen.getAllByText('Votos por hora').length).toBeGreaterThanOrEqual(2);

    const summaryCards = screen.getAllByRole('heading', { level: 4 });
    const summaryValues = summaryCards.map((heading) => heading.textContent);

    expect(summaryValues).toContain('150');
    expect(summaryValues).toContain('2');

    const hourlyTable = screen.getByRole('table');
    expect(within(hourlyTable).getByText('Hora')).toBeInTheDocument();
    expect(within(hourlyTable).getByText('Total de votos')).toBeInTheDocument();
    expect(within(hourlyTable).getByText('40')).toBeInTheDocument();
    expect(within(hourlyTable).getAllByText('55')).toHaveLength(2);
  });

  it('mostra votos por participante e histórico de votações encerradas', async () => {
    mockApi.getCurrentElection.mockResolvedValue(runningElection);
    mockApi.getPastElections.mockResolvedValue(pastElections);

    renderWithTheme(<AdminPage />);
    await waitForAdminLoaded();

    expect(screen.getByText('Votos por participante')).toBeInTheDocument();
    expect(screen.getByText(/90 votos — 60.00%/i)).toBeInTheDocument();
    expect(screen.getByText(/60 votos — 40.00%/i)).toBeInTheDocument();

    expect(screen.getByText('Votações encerradas')).toBeInTheDocument();
    expect(screen.getByText('320')).toBeInTheDocument();
    expect(screen.getByText(/ana silva: 200 votos/i)).toBeInTheDocument();
    expect(screen.getByText(/bruno costa: 120 votos/i)).toBeInTheDocument();
  });

  it('mostra alerta de erro quando chamadas da API falham', async () => {
    mockApi.getParticipants.mockRejectedValue(new Error('Falha ao carregar participantes'));

    renderWithTheme(<AdminPage />);

    expect(await screen.findByText('Falha ao carregar participantes')).toBeInTheDocument();
  });

  it('não deixa intervalos pendentes após desmontar o componente', async () => {
    const clearIntervalSpy = jest.spyOn(window, 'clearInterval');

    mockApi.getCurrentElection.mockResolvedValue(runningElection);

    const { unmount } = renderWithTheme(<AdminPage />);
    await waitForAdminLoaded();

    unmount();

    expect(clearIntervalSpy).toHaveBeenCalled();
    clearIntervalSpy.mockRestore();
  });
});
