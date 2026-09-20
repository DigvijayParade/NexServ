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
exports.authRouter = void 0;
const express_1 = require("express");
const admin = __importStar(require("firebase-admin"));
exports.authRouter = (0, express_1.Router)();
// POST /auth/register - Register new user, role-based onboarding flow
exports.authRouter.post('/register', async (req, res, next) => {
    try {
        const { uid, role, email, phone, name, language_preference, service_category } = req.body;
        if (!uid || !role || !name) {
            res.status(400).json({ code: 'invalid-request', message: 'Missing required fields: uid, role, name.' });
            return;
        }
        if (!['customer', 'worker', 'admin'].includes(role)) {
            res.status(400).json({ code: 'invalid-role', message: 'Role must be customer, worker, or admin.' });
            return;
        }
        const timestamp = admin.firestore.FieldValue.serverTimestamp();
        const userDoc = {
            uid,
            role,
            email: email || '',
            phone: phone || '',
            name,
            profile_picture_url: '',
            created_at: timestamp,
            updated_at: timestamp,
            is_active: true,
            language_preference: language_preference || 'en'
        };
        const batch = req.db.batch();
        const userRef = req.db.collection('users').doc(uid);
        batch.set(userRef, userDoc);
        if (role === 'worker') {
            const workerRef = req.db.collection('workers').doc(uid);
            const workerDoc = Object.assign(Object.assign({}, userDoc), { service_category: service_category || 'General', verification_status: 'pending', aadhaar_id: '', e_shram_id: '', national_id_verified: false, average_rating: 0, total_jobs_completed: 0, acceptance_rate: 100, today_earnings: 0, total_earnings: 0, bank_account: '', documents: [] });
            batch.set(workerRef, workerDoc);
        }
        await batch.commit();
        res.status(201).json({ status: 'success', message: 'User registered successfully.' });
    }
    catch (error) {
        next(error);
    }
});
//# sourceMappingURL=auth.js.map