import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import VotingPage from './page';
import { renderWithTheme } from '@/test-utils/render';
import { mockApi } from '@/test-utils/mocks/api';
import {
  runningElection,
  results,
  updatedResultsAfterVote,
} from '@/test-utils/fixtures/voting';

jest.mock('@/lib/api');

describe('VotingPage', () => {
  beforeEach(() => {
    jest.useFakeTimers({ advanceTimers: true });
    mockApi.getCurrentElection.mockResolvedValue(null);
    mockApi.getResults.mockResolvedValue(results);
    mockApi.vote.mockResolvedValue(updatedResultsAfterVote);
  });

  afterEach(() => {
    jest.runOnlyPendingTimers();
    jest.clearAllTimers();
    jest.useRealTimers();
    jest.clearAllMocks();
  });

  it('mostra estado de loading inicialmente', () => {
    mockApi.getCurrentElection.mockImplementation(
      () => new Promise(() => {}),
    );

    renderWithTheme(<VotingPage />);

    expect(screen.getByText('Carregando votação...')).toBeInTheDocument();
    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('mostra aviso quando não há votação ativa', async () => {
    mockApi.getCurrentElection.mockResolvedValue(null);

    renderWithTheme(<VotingPage />);

    expect(
      await screen.findByText('Nenhuma votação está em andamento no momento.'),
    ).toBeInTheDocument();
  });

  it('renderiza participantes e resultados quando há votação em andamento', async () => {
    mockApi.getCurrentElection.mockResolvedValue(runningElection);
    mockApi.getResults.mockResolvedValue(results);

    renderWithTheme(<VotingPage />);

    expect(await screen.findByRole('heading', { name: 'Votação' })).toBeInTheDocument();
    expect(screen.getByText('Ana Silva')).toBeInTheDocument();
    expect(screen.getByText('Bruno Costa')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /votar em ana silva/i })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /votar em bruno costa/i })).toBeInTheDocument();
    expect(screen.getByText(/total geral de votos/i)).toBeInTheDocument();
    expect(screen.getByText('150')).toBeInTheDocument();
    expect(screen.getByText('90 votos')).toBeInTheDocument();
    expect(screen.getByText('60.00%')).toBeInTheDocument();
    expect(screen.getByText('60 votos')).toBeInTheDocument();
    expect(screen.getByText('40.00%')).toBeInTheDocument();
  });

  it('registra voto com sucesso e atualiza resultados na tela', async () => {
    const user = userEvent.setup({ advanceTimers: jest.advanceTimersByTime });

    mockApi.getCurrentElection.mockResolvedValue(runningElection);
    mockApi.getResults.mockResolvedValue(results);
    mockApi.vote.mockResolvedValue(updatedResultsAfterVote);

    renderWithTheme(<VotingPage />);

    await screen.findByRole('button', { name: /votar em ana silva/i });

    await user.click(screen.getByRole('button', { name: /votar em ana silva/i }));

    await waitFor(() => {
      expect(mockApi.vote).toHaveBeenCalledWith(1);
    });

    expect(
      await screen.findByText('Voto computado com sucesso!'),
    ).toBeInTheDocument();
    expect(screen.getByText('151')).toBeInTheDocument();
    expect(screen.getByText('91 votos')).toBeInTheDocument();
    expect(screen.getByText('60.26%')).toBeInTheDocument();
  });

  it('mostra mensagem de erro quando o voto falha', async () => {
    const user = userEvent.setup({ advanceTimers: jest.advanceTimersByTime });

    mockApi.getCurrentElection.mockResolvedValue(runningElection);
    mockApi.getResults.mockResolvedValue(results);
    mockApi.vote.mockRejectedValue(new Error('Falha ao registrar voto'));

    renderWithTheme(<VotingPage />);

    await screen.findByRole('button', { name: /votar em bruno costa/i });
    await user.click(screen.getByRole('button', { name: /votar em bruno costa/i }));

    expect(await screen.findByText('Falha ao registrar voto')).toBeInTheDocument();
  });

  it('recarrega dados ao clicar em atualizar', async () => {
    const user = userEvent.setup({ advanceTimers: jest.advanceTimersByTime });

    mockApi.getCurrentElection.mockResolvedValue(runningElection);
    mockApi.getResults.mockResolvedValue(results);

    renderWithTheme(<VotingPage />);

    await screen.findByRole('heading', { name: 'Votação' });

    mockApi.getCurrentElection.mockClear();
    mockApi.getResults.mockClear();

    await user.click(screen.getByRole('button', { name: /atualizar/i }));

    await waitFor(() => {
      expect(mockApi.getCurrentElection).toHaveBeenCalled();
      expect(mockApi.getResults).toHaveBeenCalled();
    });
  });

  it('não deixa intervalos pendentes após desmontar o componente', async () => {
    const clearIntervalSpy = jest.spyOn(window, 'clearInterval');

    mockApi.getCurrentElection.mockResolvedValue(runningElection);
    mockApi.getResults.mockResolvedValue(results);

    const { unmount } = renderWithTheme(<VotingPage />);

    await screen.findByRole('heading', { name: 'Votação' });

    unmount();

    expect(clearIntervalSpy).toHaveBeenCalled();
    clearIntervalSpy.mockRestore();
  });
});
