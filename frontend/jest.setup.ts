import '@testing-library/jest-dom';
import React from 'react';

jest.mock('next/link', () => {
  return function MockLink({
    children,
    href,
    ...rest
  }: React.PropsWithChildren<{ href: string } & Record<string, unknown>>) {
    return React.createElement('a', { href, ...rest }, children);
  };
});
