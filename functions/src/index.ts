import * as functions from 'firebase-functions';
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import express from 'express';
import cors from 'cors';

// Initialize Firebase Admin with Service Account if present (for Render/External servers)
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    initializeApp({
      credential: cert(serviceAccount)
    });
  } catch (e) {
    console.error("Failed to parse FIREBASE_SERVICE_ACCOUNT env var, falling back to default:", e);
    initializeApp();
  }
} else {
  initializeApp();
}

const db = getFirestore();

import { authRouter } from './routes/auth';
import { jobsRouter } from './routes/jobs';
import { workersRouter } from './routes/workers';
import { adminRouter } from './routes/admin';
import { errorHandler } from './middlewares';

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

app.use((req, res, next) => {
  req.db = db;
  next();
});

app.use('/api/auth', authRouter);
app.use('/api/jobs', jobsRouter);
app.use('/api/workers', workersRouter);
app.use('/api/admin', adminRouter);

app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`NexServ backend API server running on port ${PORT}`);
});

export const api = functions.https.onRequest(app);
