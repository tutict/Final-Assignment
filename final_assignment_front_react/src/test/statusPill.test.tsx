import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import StatusPill from '../components/StatusPill';

describe('StatusPill', () => {
  it('renders the localized label for a status code', () => {
    render(<StatusPill value="Under_Review" />);
    expect(screen.getByText('审核中')).toBeInTheDocument();
  });

  it('uses field-aware labels for ambiguous codes', () => {
    render(<StatusPill value="Pending" field="paymentStatus" />);
    expect(screen.getByText('待支付')).toBeInTheDocument();
  });

  it('falls back to 未知 for empty values', () => {
    render(<StatusPill value="" />);
    expect(screen.getByText('未知')).toBeInTheDocument();
  });
});
