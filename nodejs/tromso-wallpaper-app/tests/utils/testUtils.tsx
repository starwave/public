// tests/utils/testUtils.tsx
import { ReactElement } from 'react';
import { render, RenderOptions } from '@testing-library/react';

// Custom render function with providers if needed
const customRender = (
    ui: ReactElement,
    options?: Omit<RenderOptions, 'wrapper'>
) => {
    return render(ui, { ...options });
};

export * from '@testing-library/react';
export { customRender as render };