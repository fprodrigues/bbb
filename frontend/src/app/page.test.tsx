import { screen } from '@testing-library/react';
import HomePage from './page';
import { renderWithTheme } from '@/test-utils/render';

describe('HomePage', () => {
  it('renderiza o título principal', () => {
    renderWithTheme(<HomePage />);

    expect(
      screen.getByRole('heading', { name: 'Sistema de Votação BBB' }),
    ).toBeInTheDocument();
  });

  it('renderiza botões de navegação com hrefs corretos', () => {
    renderWithTheme(<HomePage />);

    const adminLink = screen.getByRole('link', { name: /entrar no admin/i });
    const votingLink = screen.getByRole('link', { name: /ir para votação/i });

    expect(adminLink).toHaveAttribute('href', '/admin');
    expect(votingLink).toHaveAttribute('href', '/votacao');
  });

  it('renderiza descrições principais das áreas', () => {
    renderWithTheme(<HomePage />);

    expect(
      screen.getByText(
        'Escolha uma área para começar: painel administrativo ou votação pública.',
      ),
    ).toBeInTheDocument();

    expect(
      screen.getByText(
        /crie uma votação, selecione dois participantes, inicie, encerre/i,
      ),
    ).toBeInTheDocument();

    expect(
      screen.getByText(
        /vote em um dos participantes disponíveis e veja o resultado percentual/i,
      ),
    ).toBeInTheDocument();
  });

  it('renderiza títulos das seções Admin e Votação', () => {
    renderWithTheme(<HomePage />);

    expect(screen.getByRole('heading', { name: 'Admin' })).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'Votação' })).toBeInTheDocument();
  });
});
