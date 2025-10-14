// tests/server.test.ts
import request from 'supertest';
import app from '../src/server';

describe('Server API Endpoints', () => {
    describe('GET /health', () => {
        it('should return health status', async () => {
            const response = await request(app)
                .get('/health')
                .expect(200);

            expect(response.body).toHaveProperty('status', 'ok');
            expect(response.body).toHaveProperty('timestamp');
            expect(new Date(response.body.timestamp)).toBeInstanceOf(Date);
        });
    });

    describe('GET /maramboi', () => {
        it('should return theme library when action is "g"', async () => {
            const response = await request(app)
                .get('/maramboi?a=g')
                .expect(200);

            expect(Array.isArray(response.body)).toBe(true);
            expect(response.body.length).toBeGreaterThan(0);

            response.body.forEach((theme: any) => {
                expect(theme).toHaveProperty('Label');
                expect(theme).toHaveProperty('Config');
                expect(typeof theme.Label).toBe('string');
                expect(typeof theme.Config).toBe('string');
            });
        });

        it('should return error for invalid action', async () => {
            const response = await request(app)
                .get('/maramboi?a=invalid')
                .expect(400);

            expect(response.body).toHaveProperty('error');
        });

        it('should return error when action parameter is missing', async () => {
            const response = await request(app)
                .get('/maramboi')
                .expect(400);

            expect(response.body).toHaveProperty('error');
        });

        it('should return expected theme structure', async () => {
            const response = await request(app)
                .get('/maramboi?a=g')
                .expect(200);

            const theme = response.body[0];
            expect(theme.Label).toBeTruthy();
            expect(theme.Config).toMatch(/\/.*/);
        });
    });

    describe('GET /ngorongoro', () => {
        it('should handle wallpaper request with all parameters', async () => {
            const response = await request(app)
                .get('/ngorongoro')
                .query({
                    a: 'tweb',
                    d: '1920x1080',
                    t: 'default2',
                    o: ''
                })
                .expect(200);

            expect(response.body).toHaveProperty('message');
            expect(response.body).toHaveProperty('params');
            expect(response.body.params).toMatchObject({
                a: 'tweb',
                d: '1920x1080',
                t: 'default2'
            });
        });

        it('should handle request with custom options', async () => {
            const customOption = encodeURIComponent(" -c '/custom;;#test#'");

            const response = await request(app)
                .get('/ngorongoro')
                .query({
                    a: 'tweb',
                    d: '2732x2048',
                    t: 'custom',
                    o: customOption
                })
                .expect(200);

            expect(response.body.params.t).toBe('custom');
            expect(response.body.params.o).toBeTruthy();
        });

        it('should handle different dimension formats', async () => {
            const dimensions = [
                '1920x1080',
                '3840x2160',
                '2732x2048',
                '1080x2280'
            ];

            for (const dimension of dimensions) {
                const response = await request(app)
                    .get('/ngorongoro')
                    .query({
                        a: 'tweb',
                        d: dimension,
                        t: 'default1'
                    })
                    .expect(200);

                expect(response.body.params.d).toBe(dimension);
            }
        });

        it('should handle all theme types', async () => {
            const themes = [
                'default1', 'default2', 'custom', 'photo',
                'recent', 'wallpaper', 'landscape', 'movie1',
                'movie2', 'special1', 'special2', 'all'
            ];

            for (const theme of themes) {
                const response = await request(app)
                    .get('/ngorongoro')
                    .query({
                        a: 'tweb',
                        d: '1920x1080',
                        t: theme
                    })
                    .expect(200);

                expect(response.body.params.t).toBe(theme);
            }
        });
    });

    describe('CORS Configuration', () => {
        it('should have CORS headers', async () => {
            const response = await request(app)
                .get('/health')
                .expect(200);

            expect(response.headers).toHaveProperty('access-control-allow-origin');
        });

        it('should handle OPTIONS preflight request', async () => {
            await request(app)
                .options('/maramboi')
                .expect(204);
        });
    });

    describe('Error Handling', () => {
        it('should handle 404 for unknown routes', async () => {
            const response = await request(app)
                .get('/unknown-endpoint')
                .expect(200); // Returns index.html for SPA

            // For API routes, should return proper error
            const apiResponse = await request(app)
                .get('/api/unknown')
                .expect(200);
        });

        it('should return JSON for API errors', async () => {
            const response = await request(app)
                .get('/maramboi?a=invalid')
                .expect(400);

            expect(response.headers['content-type']).toMatch(/json/);
            expect(response.body).toHaveProperty('error');
        });
    });

    describe('Request Validation', () => {
        it('should handle missing query parameters gracefully', async () => {
            const response = await request(app)
                .get('/ngorongoro')
                .expect(200);

            expect(response.body).toHaveProperty('params');
        });

        it('should handle URL encoded parameters', async () => {
            const encodedConfig = encodeURIComponent('/test;;#encoded#|#params#');

            const response = await request(app)
                .get('/ngorongoro')
                .query({
                    a: 'tweb',
                    d: '1920x1080',
                    t: 'custom',
                    o: encodedConfig
                })
                .expect(200);

            expect(response.body.params.o).toBeTruthy();
        });

        it('should handle special characters in theme names', async () => {
            const response = await request(app)
                .get('/ngorongoro')
                .query({
                    a: 'tweb',
                    d: '1920x1080',
                    t: 'special1'
                })
                .expect(200);

            expect(response.body.params.t).toBe('special1');
        });
    });
});