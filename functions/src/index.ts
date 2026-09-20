import * as functions from 'firebase-functions';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import express from 'express';
import cors from 'cors';

initializeApp();
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

export const api = functions.https.onRequest(app);
