import { Request, Response, NextFunction } from 'express';
import { getAuth, DecodedIdToken } from 'firebase-admin/auth';
import { FieldValue, Firestore } from 'firebase-admin/firestore';

declare global {
  namespace Express {
    interface Request {
      user?: DecodedIdToken;
      db: Firestore;
    }
  }
}

export const errorHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
  console.error('[ERROR] ', err);
  
  req.db.collection('system_logs').add({
    type: 'error',
    endpoint: req.url,
    method: req.method,
    error_message: err.message || 'Internal Server Error',
    timestamp: FieldValue.serverTimestamp(),
    user_id: req.user?.uid || null
  }).catch((e: any) => console.error('Failed to log error to Firestore', e));

  res.status(err.status || 500).json({
    code: err.code || 'internal-error',
    message: err.message || 'An unexpected error occurred.',
    status: err.status || 500
  });
};

export const authenticateUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ code: 'unauthorized', message: 'Missing or invalid authorization token.', status: 401 });
    return;
  }

  const token = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await getAuth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    res.status(401).json({ code: 'unauthorized', message: 'Invalid or expired token.', status: 401 });
  }
};

export const requireRole = (roles: Array<'customer' | 'worker' | 'admin'>) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    if (!req.user) {
      res.status(401).json({ code: 'unauthorized', message: 'User not authenticated.', status: 401 });
      return;
    }
    try {
      const userDoc = await req.db.collection('users').doc(req.user.uid).get();
      if (!userDoc.exists) {
        res.status(403).json({ code: 'forbidden', message: 'User profile not found in database.', status: 403 });
        return;
      }
      const userData = userDoc.data();
      if (!userData || !roles.includes(userData.role)) {
        res.status(403).json({ code: 'forbidden', message: 'Access denied.', status: 403 });
        return;
      }
      next();
    } catch (error) {
      next(error);
    }
  };
};
