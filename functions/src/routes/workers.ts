import { Router, Request, Response, NextFunction } from 'express';
import { authenticateUser } from '../middlewares';

export const workersRouter = Router();

workersRouter.get('/:id/profile', authenticateUser, async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const workerId = req.params.id as string;
    const workerDoc = await req.db.collection('workers').doc(workerId).get();

    if (!workerDoc.exists) {
      res.status(404).json({ code: 'not-found', message: 'Worker profile not found.' });
      return;
    }

    const workerData = workerDoc.data();
    
    if (req.user!.uid !== workerId) {
      delete workerData?.bank_account;
      delete workerData?.aadhaar_id;
    }

    res.status(200).json({ status: 'success', data: workerData });
  } catch (error) {
    next(error);
  }
});
