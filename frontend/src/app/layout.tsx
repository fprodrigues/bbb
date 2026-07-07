'use client';

import type { ReactNode } from 'react';
import { ThemeProvider } from '@mui/material/styles';
import {
  AppBar,
  Box,
  CssBaseline,
  Toolbar,
  Typography,
} from '@mui/material';
import HowToVoteIcon from '@mui/icons-material/HowToVote';
import theme from './theme';

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="pt-BR">
      <body>
        <ThemeProvider theme={theme}>
          <CssBaseline />

          <AppBar position="static" elevation={0}>
            <Toolbar>
              <HowToVoteIcon sx={{ mr: 1 }} />
              <Typography variant="h6">
                BBB Voting Challenge
              </Typography>
            </Toolbar>
          </AppBar>

          <Box
            component="main"
            sx={{
              minHeight: 'calc(100vh - 64px)',
              bgcolor: 'background.default',
              py: 4,
            }}
          >
            {children}
          </Box>
        </ThemeProvider>
      </body>
    </html>
  );
}