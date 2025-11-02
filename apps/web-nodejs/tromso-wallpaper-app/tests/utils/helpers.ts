// tests/utils/helpers.ts
export const waitForMs = (ms: number) =>
    new Promise(resolve => setTimeout(resolve, ms));

export { mockThemeLibrary } from './mockData';

export const mockFetch = (data: unknown, ok = true) => {
    global.fetch = jest.fn(() =>
        Promise.resolve({
            ok,
            json: async () => data,
            text: async () => JSON.stringify(data),
        })
    ) as jest.Mock;
};

export const mockLocalStorage = () => {
    const store: { [key: string]: string } = {};

    return {
        getItem: jest.fn((key: string) => store[key] || null),
        setItem: jest.fn((key: string, value: string) => {
            store[key] = value;
        }),
        removeItem: jest.fn((key: string) => {
            delete store[key];
        }),
        clear: jest.fn(() => {
            Object.keys(store).forEach(key => delete store[key]);
        }),
    };
};

export const createTouchEvent = (
    type: string,
    touches: { clientX: number; clientY: number }[]
) => {
    return new TouchEvent(type, {
        touches: touches as unknown as Touch[],
        bubbles: true,
        cancelable: true,
    });
};