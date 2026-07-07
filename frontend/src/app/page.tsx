'use client';

import Link from 'next/link';
import {
  Box,
  Button,
  Card,
  CardContent,
  Container,
  Grid,
  Stack,
  Typography,
} from '@mui/material';
import AdminPanelSettingsIcon from '@mui/icons-material/AdminPanelSettings';
import HowToVoteIcon from '@mui/icons-material/HowToVote';
import BarChartIcon from '@mui/icons-material/BarChart';

export default function HomePage() {
  return (
    <Container maxWidth="md">
      <Stack spacing={4}  sx={{ alignItems: 'center' }}>
        <Box sx={{ textAlign: 'center' }}>
          <Typography variant="h4" gutterBottom>
            Sistema de Votação BBB
          </Typography>

          <Typography variant="body1" color="text.secondary">
            Escolha uma área para começar: painel administrativo ou votação pública.
          </Typography>
        </Box>

        <Grid container spacing={3}>
          <Grid size={{ xs: 12, md: 6 }}>
            <Card elevation={0} sx={{ height: '100%' }}>
              <CardContent>
                <Stack spacing={2}  sx={{ alignItems: 'flex-start' }}>
                  <AdminPanelSettingsIcon color="primary" sx={{ fontSize: 56 }} />

                  <Typography variant="h5">
                    Admin
                  </Typography>

                  <Typography color="text.secondary">
                    Crie uma votação, selecione dois participantes, inicie, encerre
                    e acompanhe os dados exigidos pelo desafio.
                  </Typography>

                  <Button
                    component={Link}
                    href="/admin"
                    variant="contained"
                    size="large"
                    startIcon={<BarChartIcon />}
                    fullWidth
                  >
                    Entrar no Admin
                  </Button>
                </Stack>
              </CardContent>
            </Card>
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <Card elevation={0} sx={{ height: '100%' }}>
              <CardContent>
                <Stack spacing={2}  sx={{ alignItems: 'flex-start' }}>
                  <HowToVoteIcon color="secondary" sx={{ fontSize: 56 }} />

                  <Typography variant="h5">
                    Votação
                  </Typography>

                  <Typography color="text.secondary">
                    Vote em um dos participantes disponíveis e veja o resultado
                    percentual atualizado após o voto.
                  </Typography>

                  <Button
                    component={Link}
                    href="/votacao"
                    variant="contained"
                    color="secondary"
                    size="large"
                    startIcon={<HowToVoteIcon />}
                    fullWidth
                  >
                    Ir para Votação
                  </Button>
                </Stack>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </Stack>
    </Container>
  );
}