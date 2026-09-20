"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireRole = exports.authenticateUser = exports.errorHandler = void 0;
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-admin/firestore");
const errorHandler = (err, req, res, next) => {
    var _a;
    console.error('[ERROR] ', err);
    req.db.collection('system_logs').add({
        type: 'error',
        endpoint: req.url,
        method: req.method,
        error_message: err.message || 'Internal Server Error',
        timestamp: firestore_1.FieldValue.serverTimestamp(),
        user_id: ((_a = req.user) === null || _a === void 0 ? void 0 : _a.uid) || null
    }).catch((e) => console.error('Failed to log error to Firestore', e));
    res.status(err.status || 500).json({
        code: err.code || 'internal-error',
        message: err.message || 'An unexpected error occurred.',
        status: err.status || 500
    });
};
exports.errorHandler = errorHandler;
const authenticateUser = async (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ code: 'unauthorized', message: 'Missing or invalid authorization token.', status: 401 });
        return;
    }
    const token = authHeader.split('Bearer ')[1];
    try {
        const decodedToken = await (0, auth_1.getAuth)().verifyIdToken(token);
        req.user = decodedToken;
        next();
    }
    catch (error) {
        res.status(401).json({ code: 'unauthorized', message: 'Invalid or expired token.', status: 401 });
    }
};
exports.authenticateUser = authenticateUser;
const requireRole = (roles) => {
    return async (req, res, next) => {
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
        }
        catch (error) {
            next(error);
        }
    };
};
exports.requireRole = requireRole;
//# sourceMappingURL=middlewares.js.map