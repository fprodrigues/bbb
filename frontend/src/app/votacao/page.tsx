'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  Alert,
  Avatar,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Container,
  LinearProgress,
  Grid,
  Stack,
  Typography,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import HowToVoteIcon from '@mui/icons-material/HowToVote';
import RefreshIcon from '@mui/icons-material/Refresh';
import { api } from '@/lib/api';
import { Election, ResultsResponse } from '@/types/voting';

export default function VotingPage() {
  const [election, setElection] = useState<Election | null>(null);
  const [results, setResults] = useState<ResultsResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [votingParticipantId, setVotingParticipantId] = useState<number | null>(null);
  const [error, setError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  async function loadData() {
    setError('');

    try {
      const currentElection = await api.getCurrentElection();
      setElection(currentElection);

      if (currentElection?.status === 'running') {
        const currentResults = await api.getResults();
        setResults(currentResults);
      } else {
        setResults(null);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao carregar votação.');
    } finally {
      setLoading(false);
    }
  }

  async function handleVote(participantId: number) {
    setVotingParticipantId(participantId);
    setError('');
    setSuccessMessage('');

    try {
      const updatedResults = await api.vote(participantId);
      setResults(updatedResults);
      setSuccessMessage('Voto computado com sucesso!');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao votar.');
    } finally {
      setVotingParticipantId(null);
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
        <Stack sx={{ alignItems: 'center' }} spacing={2}>
          <CircularProgress />
          <Typography>Carregando votação...</Typography>
        </Stack>
      </Container>
    );
  }

  const hasRunningElection = election?.status === 'running';

  return (
    <Container maxWidth="lg">
      <Stack spacing={3}>
        <Box sx={{justifyContent :"space-between", display:'flex', gap:2}}>
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
            Votação
          </Typography>

          <Typography color="text.secondary">
            Escolha um dos participantes do paredão.
          </Typography>
        </Box>

        {error && (
          <Alert severity="error">
            {error}
          </Alert>
        )}

        {successMessage && (
          <Alert severity="success">
            {successMessage}
          </Alert>
        )}

        {!hasRunningElection && (
          <Alert severity="warning">
            Nenhuma votação está em andamento no momento.
          </Alert>
        )}

        {hasRunningElection && (
          <>
            <Grid container spacing={3}>
              {election.participants.map((participant) => {
                const candidateResult = results?.candidates.find(
                  (candidate) => candidate.participant_id === participant.id,
                );

                return (
                  <Grid size={{xs: 12, md:6}} key={participant.id}>
                    <Card elevation={0}>
                      <CardContent>
                        <Stack spacing={3} sx={{alignItems:'center', textAlign:'center'}}>
                          <Avatar
                            src={participant.avatar_url || undefined}
                            alt={participant.name}
                            sx={{
                              width: 120,
                              height: 120,
                              fontSize: 42,
                              bgcolor: 'primary.main',
                            }}
                          >
                            {participant.name.charAt(0)}
                          </Avatar>

                          <Box>
                            <Typography variant="h5">
                              {participant.name}
                            </Typography>

                            <Chip
                              label="Disponível para voto"
                              color="success"
                              size="small"
                              sx={{ mt: 1 }}
                            />
                          </Box>

                          <Button
                            variant="contained"
                            size="large"
                            color="secondary"
                            startIcon={<HowToVoteIcon />}
                            disabled={votingParticipantId !== null}
                            onClick={() => handleVote(participant.id)}
                            fullWidth
                          >
                            {votingParticipantId === participant.id
                              ? 'Votando...'
                              : `Votar em ${participant.name}`}
                          </Button>

                          {candidateResult && (
                            <Box sx={{width:'100%'}}>
                              <Box sx={{display:'flex', justifyContent:'space-between', mb:1}} >
                                <Typography variant="body2">
                                  {candidateResult.votes} votos
                                </Typography>

                                <Typography variant="body2" sx={{fontWeight:700}}>
                                  {candidateResult.percentage.toFixed(2)}%
                                </Typography>
                              </Box>

                              <LinearProgress
                                variant="determinate"
                                value={candidateResult.percentage}
                                sx={{ height: 10, borderRadius: 999 }}
                              />
                            </Box>
                          )}
                        </Stack>
                      </CardContent>
                    </Card>
                  </Grid>
                );
              })}
            </Grid>

            <Card elevation={0}>
              <CardContent>
                <Stack spacing={1}>
                  <Typography variant="h6">
                    Panorama atual
                  </Typography>

                  <Typography color="text.secondary">
                    Total geral de votos: <strong>{results?.total_votes ?? 0}</strong>
                  </Typography>
                </Stack>
              </CardContent>
            </Card>
          </>
        )}
      </Stack>
    </Container>
  );
}