import { render, type RenderOptions } from '@testing-library/react';
import { ThemeProvider } from '@mui/material/styles';
import type { ReactElement, ReactNode } from 'react';
import theme from '@/app/theme';

function AllProviders({ children }: { children: ReactNode }) {
  return <ThemeProvider theme={theme}>{children}</ThemeProvider>;
}

export function renderWithTheme(ui: ReactElement, options?: Omit<RenderOptions, 'wrapper'>) {
  return render(ui, { wrapper: AllProviders, ...options });
}
