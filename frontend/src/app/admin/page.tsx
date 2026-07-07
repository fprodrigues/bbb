'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import {
  Alert,
  Avatar,
  Box,
  Button,
  Card,
  CardContent,
  Checkbox,
  Chip,
  CircularProgress,
  Container,
  Divider,
  FormControlLabel,
  LinearProgress,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography,
} from '@mui/material';
import Grid from '@mui/material/Grid';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import StopIcon from '@mui/icons-material/Stop';
import AddCircleIcon from '@mui/icons-material/AddCircle';
import RefreshIcon from '@mui/icons-material/Refresh';
import { api } from '@/lib/api';
import {
  Election,
  HourlyResponse,
  Participant,
  PastElection,
  ResultsResponse,
} from '@/types/voting';

export default function AdminPage() {
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [selectedParticipantIds, setSelectedParticipantIds] = useState<number[]>([]);
  const [currentElection, setCurrentElection] = useState<Election | null>(null);
  const [results, setResults] = useState<ResultsResponse | null>(null);
  const [hourlyResults, setHourlyResults] = useState<HourlyResponse | null>(null);
  const [pastElections, setPastElections] = useState<PastElection[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const canCreateElection = selectedParticipantIds.length === 2;
  const canStartElection = currentElection?.status === 'draft';
  const canCloseElection = currentElection?.status === 'running';

  const statusLabel = useMemo(() => {
    if (!currentElection) return 'Nenhuma votação criada';

    const labels = {
      draft: 'Criada, aguardando início',
      running: 'Em andamento',
      closed: 'Encerrada',
    };

    return labels[currentElection.status];
  }, [currentElection]);

  async function loadData() {
    setError('');

    try {
      const [
        participantsData,
        electionData,
        historyData,
      ] = await Promise.all([
        api.getParticipants(),
        api.getCurrentElection(),
        api.getPastElections(),
      ]);

      setParticipants(participantsData);
      setCurrentElection(electionData);
      setPastElections(historyData);

      if (electionData) {
        const [resultsData, hourlyData] = await Promise.all([
          api.getResults(),
          api.getHourlyResults(),
        ]);

        setResults(resultsData);
        setHourlyResults(hourlyData);
      } else {
        setResults(null);
        setHourlyResults(null);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao carregar admin.');
    } finally {
      setLoading(false);
    }
  }

  function toggleParticipant(participantId: number) {
    setSelectedParticipantIds((current) => {
      if (current.includes(participantId)) {
        return current.filter((id) => id !== participantId);
      }

      if (current.length >= 2) {
        return current;
      }

      return [...current, participantId];
    });
  }

  async function handleCreateElection() {
    if (!canCreateElection) return;

    setActionLoading(true);
    setError('');
    setSuccess('');

    try {
      const election = await api.createElection(selectedParticipantIds);
      setCurrentElection(election);
      setSuccess('Votação criada com sucesso.');
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao criar votação.');
    } finally {
      setActionLoading(false);
    }
  }

  async function handleStartElection() {
    if (!currentElection) return;

    setActionLoading(true);
    setError('');
    setSuccess('');

    try {
      await api.startElection(currentElection.id);
      setSuccess('Votação iniciada com sucesso.');
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao iniciar votação.');
    } finally {
      setActionLoading(false);
    }
  }

  async function handleCloseElection() {
    if (!currentElection) return;

    setActionLoading(true);
    setError('');
    setSuccess('');

    try {
      await api.closeElection(currentElection.id);
      setSuccess('Votação encerrada com sucesso.');
      await loadData();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao encerrar votação.');
    } finally {
      setActionLoading(false);
    }
  }

  useEffect(() => {
    loadData();

    const interval = window.setInterval(() => {
      loadData();
    }, 5000);

    return () => window.clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <Container maxWidth="md">
        <Stack sx={{alignItems:'center'}} spacing={2}>
          <CircularProgress />
          <Typography>Carregando painel admin...</Typography>
        </Stack>
      </Container>
    );
  }

  return (
    <Container maxWidth="xl">
      <Stack spacing={3}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', gap: 2 }}>
          <Button
            component={Link}
            href="/"
            startIcon={<ArrowBackIcon />}
          >
            Voltar
          </Button>

          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={loadData}
          >
            Atualizar
          </Button>
        </Box>

        <Box>
          <Typography variant="h4" gutterBottom>
            Painel Administrativo
          </Typography>

          <Typography color="text.secondary">
            Crie, inicie, encerre e monitore votações.
          </Typography>
        </Box>

        <Alert severity="info">
          Este admin está sem autenticação para reduzir o escopo do teste.
          Em produção, esta área deveria ter autenticação, autorização e auditoria.
        </Alert>

        {error && (
          <Alert severity="error">
            {error}
          </Alert>
        )}

        {success && (
          <Alert severity="success">
            {success}
          </Alert>
        )}

        <Grid container spacing={3}>
          <Grid size={{ xs: 12, lg: 4 }}>
            <Card elevation={0}>
              <CardContent>
                <Stack spacing={2}>
                  <Typography variant="h6">
                    Criar votação
                  </Typography>

                  <Typography variant="body2" color="text.secondary">
                    Selecione exatamente dois participantes para formar o paredão.
                  </Typography>

                  <Divider />

                  <Stack spacing={1}>
                    {participants.map((participant) => {
                      const selected = selectedParticipantIds.includes(participant.id);
                      const disabled =
                        !selected && selectedParticipantIds.length >= 2;

                      return (
                        <Paper
                          key={participant.id}
                          variant="outlined"
                          sx={{
                            p: 1.5,
                            opacity: disabled ? 0.5 : 1,
                          }}
                        >
                          <FormControlLabel
                            control={
                              <Checkbox
                                checked={selected}
                                disabled={disabled}
                                onChange={() => toggleParticipant(participant.id)}
                              />
                            }
                            label={
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                                <Avatar
                                  src={participant.avatar_url || undefined}
                                  sx={{ width: 32, height: 32 }}
                                >
                                  {participant.name.charAt(0)}
                                </Avatar>

                                <Typography>
                                  {participant.name}
                                </Typography>
                              </Box>
                            }
                          />
                        </Paper>
                      );
                    })}
                  </Stack>

                  <Button
                    variant="contained"
                    size="large"
                    startIcon={<AddCircleIcon />}
                    disabled={!canCreateElection || actionLoading}
                    onClick={handleCreateElection}
                    fullWidth
                  >
                    Criar votação
                  </Button>
                </Stack>
              </CardContent>
            </Card>
          </Grid>

          <Grid size={{ xs: 12, lg: 8 }}>
            <Stack spacing={3}>
              <Card elevation={0}>
                <CardContent>
                  <Stack spacing={2}>
                    <Box sx={{ display: 'flex', justifyContent: 'space-between', gap: 2, flexWrap: 'wrap' }}>
                      <Box>
                        <Typography variant="h6">
                          Votação atual
                        </Typography>

                        <Typography color="text.secondary">
                          Status operacional da votação.
                        </Typography>
                      </Box>

                      <Chip
                        label={statusLabel}
                        color={
                          currentElection?.status === 'running'
                            ? 'success'
                            : currentElection?.status === 'draft'
                              ? 'warning'
                              : 'default'
                        }
                      />
                    </Box>

                    <Divider />

                    {currentElection ? (
                      <Stack spacing={2}>
                        <Typography>
                          ID da votação: <strong>{currentElection.id}</strong>
                        </Typography>

                        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                          {currentElection.participants.map((participant) => (
                            <Chip
                              key={participant.id}
                              label={participant.name}
                              color="primary"
                              variant="outlined"
                            />
                          ))}
                        </Box>

                        <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                          <Button
                            variant="contained"
                            color="success"
                            startIcon={<PlayArrowIcon />}
                            disabled={!canStartElection || actionLoading}
                            onClick={handleStartElection}
                          >
                            Iniciar votação
                          </Button>

                          <Button
                            variant="contained"
                            color="error"
                            startIcon={<StopIcon />}
                            disabled={!canCloseElection || actionLoading}
                            onClick={handleCloseElection}
                          >
                            Encerrar votação
                          </Button>
                        </Box>
                      </Stack>
                    ) : (
                      <Alert severity="warning">
                        Nenhuma votação criada ou em andamento.
                      </Alert>
                    )}
                  </Stack>
                </CardContent>
              </Card>

              <Grid container spacing={3}>
                <Grid size={{ xs: 12, md: 4 }}>
                  <Card elevation={0}>
                    <CardContent>
                      <Typography variant="body2" color="text.secondary">
                        Total geral de votos
                      </Typography>

                      <Typography variant="h4">
                        {results?.total_votes ?? 0}
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>

                <Grid size={{ xs: 12, md: 4 }}>
                  <Card elevation={0}>
                    <CardContent>
                      <Typography variant="body2" color="text.secondary">
                        Participantes no paredão
                      </Typography>

                      <Typography variant="h4">
                        {currentElection?.participants.length ?? 0}
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>

                <Grid size={{ xs: 12, md: 4 }}>
                  <Card elevation={0}>
                    <CardContent>
                      <Typography variant="body2" color="text.secondary">
                        Votos por hora
                      </Typography>

                      <Typography variant="h4">
                        {hourlyResults?.hours.reduce(
                          (sum, item) => sum + item.total_votes,
                          0,
                        ) ?? 0}
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>
            </Stack>
          </Grid>
        </Grid>

        <Grid container spacing={3}>
          <Grid size={{ xs: 12, lg: 6 }}>
            <Card elevation={0}>
              <CardContent>
                <Stack spacing={2}>
                  <Typography variant="h6">
                    Votos por participante
                  </Typography>

                  {results?.candidates.length ? (
                    <Stack spacing={2}>
                      {results.candidates.map((candidate) => (
                        <Box key={candidate.participant_id}>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                            <Typography sx={{fontWeight:700}}>
                              {candidate.name}
                            </Typography>

                            <Typography>
                              {candidate.votes} votos — {candidate.percentage.toFixed(2)}%
                            </Typography>
                          </Box>

                          <LinearProgress
                            variant="determinate"
                            value={candidate.percentage}
                            sx={{ height: 10, borderRadius: 999 }}
                          />
                        </Box>
                      ))}
                    </Stack>
                  ) : (
                    <Alert severity="info">
                      Ainda não há votos computados.
                    </Alert>
                  )}
                </Stack>
              </CardContent>
            </Card>
          </Grid>

          <Grid size={{ xs: 12, lg: 6 }}>
            <Card elevation={0}>
              <CardContent>
                <Stack spacing={2}>
                  <Typography variant="h6">
                    Votos por hora
                  </Typography>

                  {hourlyResults?.hours.length ? (
                    <Table size="small">
                      <TableHead>
                        <TableRow>
                          <TableCell>Hora</TableCell>
                          <TableCell align="right">Total de votos</TableCell>
                        </TableRow>
                      </TableHead>

                      <TableBody>
                        {hourlyResults.hours.map((item) => (
                          <TableRow key={item.hour}>
                            <TableCell>
                              {formatDateTime(item.hour)}
                            </TableCell>
                            <TableCell align="right">
                              {item.total_votes}
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  ) : (
                    <Alert severity="info">
                      Ainda não há dados por hora.
                    </Alert>
                  )}
                </Stack>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        <Card elevation={0}>
          <CardContent>
            <Stack spacing={2}>
              <Typography variant="h6">
                Votações encerradas
              </Typography>

              {pastElections.length ? (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>ID</TableCell>
                      <TableCell>Início</TableCell>
                      <TableCell>Fim</TableCell>
                      <TableCell align="right">Total</TableCell>
                      <TableCell>Resultado</TableCell>
                    </TableRow>
                  </TableHead>

                  <TableBody>
                    {pastElections.map((election) => (
                      <TableRow key={election.id}>
                        <TableCell>{election.id}</TableCell>
                        <TableCell>{formatDateTime(election.started_at)}</TableCell>
                        <TableCell>{formatDateTime(election.ended_at)}</TableCell>
                        <TableCell align="right">{election.total_votes}</TableCell>
                        <TableCell>
                          <Stack sx={{direction:'row', flexWrap:'wrap'}}  spacing={1}>
                            {election.participants.map((participant) => (
                              <Chip
                                key={participant.participant_id}
                                size="small"
                                label={`${participant.name}: ${participant.votes} votos`}
                              />
                            ))}
                          </Stack>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              ) : (
                <Alert severity="info">
                  Nenhuma votação encerrada até o momento.
                </Alert>
              )}
            </Stack>
          </CardContent>
        </Card>
      </Stack>
    </Container>
  );
}

function formatDateTime(value?: string | null) {
  if (!value) return '-';

  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(new Date(value));
}