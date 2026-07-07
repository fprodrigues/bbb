import { api } from '@/lib/api';

export const mockApi = api as jest.Mocked<typeof api>;

export function resetApiMocks() {
  jest.clearAllMocks();
}
