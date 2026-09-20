"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireRole = exports.authenticateUser = exports.errorHandler = void 0;
const admin = __importStar(require("firebase-admin"));
const express_1 = require("express");
// 1. Error Handler Middleware
const errorHandler = (err, req, res, next) => {
    console.error(`[ERROR] ${req.method} ${req.url}:`, err);
    // Log error to Firestore asynchronously
    req.db.collection('system_logs').add({
        type: 'error',
        endpoint: req.url,
        method: req.method,
        body: req.body,
        error_message: err.message || 'Internal Server Error',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        user_id: req.user?.uid || null
    }).catch(e => console.error('Failed to log error to Firestore', e));
    res.status(err.status || 500).json({
        code: err.code || 'internal-error',
        message: err.message || 'An unexpected error occurred.',
        status: err.status || 500
    });
};
exports.errorHandler = errorHandler;
// 2. Authentication Middleware
const authenticateUser = async (req, res, next) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ code: 'unauthorized', message: 'Missing or invalid authorization token.', status: 401 });
        return;
    }
    const token = authHeader.split('Bearer ')[1];
    try {
        const decodedToken = await admin.auth().verifyIdToken(token);
        req.user = decodedToken;
        next();
    }
    catch (error) {
        res.status(401).json({ code: 'unauthorized', message: 'Invalid or expired token.', status: 401 });
    }
};
exports.authenticateUser = authenticateUser;
// 3. Role-Based Access Control Middleware
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
                res.status(403).json({ code: 'forbidden', message: `Access denied. Requires one of roles: ${roles.join(', ')}`, status: 403 });
                return;
            }
            // We attach full user data to req if needed later
            req.userData = userData;
            next();
        }
        catch (error) {
            next(error);
        }
    };
};
exports.requireRole = requireRole;
//# sourceMappingURL=middlewares.js.map