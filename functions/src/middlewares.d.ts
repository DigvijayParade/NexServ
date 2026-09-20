import * as admin from 'firebase-admin';
import { Request, Response, NextFunction } from 'express';
declare global {
    namespace Express {
        interface Request {
            user?: admin.auth.DecodedIdToken;
            db: admin.firestore.Firestore;
        }
    }
}
export declare const errorHandler: (err: any, req: Request, res: Response, next: NextFunction) => void;
export declare const authenticateUser: (req: Request, res: Response, next: NextFunction) => Promise<void>;
export declare const requireRole: (roles: ('customer' | 'worker' | 'admin')[]) => (req: Request, res: Response, next: NextFunction) => Promise<void>;
//# sourceMappingURL=middlewares.d.ts.map