import 'dotenv/config';
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import session from 'express-session';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import authRouter from './routes/auth.js';
import reviewRouter from './routes/review.js';
import { getAuthStatus } from './auth/provider.js';
import { checkDatabase } from './db/pool.js';

const app = express();
const port = Number(process.env.PORT || 3000);
const isProduction = process.env.NODE_ENV === 'production';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, '..');
const publicDir = path.join(projectRoot, 'public');

if (isProduction && (!process.env.SESSION_SECRET || process.env.SESSION_SECRET.length < 32)) {
  console.error('Refusing production startup: SESSION_SECRET must be at least 32 characters.');
  process.exit(1);
}
if (isProduction && !getAuthStatus().productionReady) {
  console.warn('Email authentication is not production-ready; authentication endpoints will fail closed.');
}

app.disable('x-powered-by');
if (isProduction) app.set('trust proxy', 1);
app.use(helmet({ contentSecurityPolicy: false })); // Existing page still contains inline scripts/styles; tighten CSP in a later refactor.
app.use(cors({
  origin: process.env.FRONTEND_ORIGIN || 'http://localhost:3000',
  credentials: true,
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type']
}));
app.use(express.json({ limit: '20kb' }));
app.use(session({
  name: 'sr_voting_session',
  secret: process.env.SESSION_SECRET || 'local-only-change-this-development-session-secret',
  resave: false,
  saveUninitialized: false,
  cookie: { httpOnly: true, sameSite: 'strict', secure: isProduction, maxAge: 30 * 60 * 1000 }
  // express-session's MemoryStore is development-only. Configure a persistent session store before deployment.
}));
app.use('/api', rateLimit({ windowMs: 60_000, limit: 120, standardHeaders: 'draft-7', legacyHeaders: false }));
app.use('/api/auth', authRouter);
app.use('/api/review', reviewRouter);

app.get('/api/health', async (_req, res) => {
  res.set('Cache-Control', 'no-store');
  let database = 'disconnected';
  try { await checkDatabase(); database = 'connected'; } catch (error) { database = 'error'; }
  res.status(database === 'connected' ? 200 : 503).json({
    status: database === 'connected' ? 'ok' : 'degraded', service: 'sr-university-voting-api', mode: process.env.NODE_ENV || 'development',
    database, authentication: getAuthStatus(), officialVotingEnabled: false,
    localReviewMode: process.env.REVIEW_MODE === 'true' && !isProduction,
    note: 'Local review workflow only. Use fictional test details; test ballots are not official votes.'
  });
});

app.use(express.static(publicDir));
app.get('*splat', (_req, res) => res.sendFile(path.join(publicDir, 'index.html')));
app.listen(port, () => {
  console.log(`SR University voting prototype running at http://localhost:${port}`);
  console.log(`Health check: http://localhost:${port}/api/health`);
  console.log(`Email authentication: ${getAuthStatus().mode}`);
});
