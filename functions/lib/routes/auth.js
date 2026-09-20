"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
exports.authRouter = (0, express_1.Router)();
exports.authRouter.post('/register', async (req, res, next) => {
    try {
        const { uid, role, email, phone, name, language_preference, service_category, address } = req.body;
        if (!uid || !role || !name) {
            res.status(400).json({ code: 'invalid-request', message: 'Missing required fields: uid, role, name.' });
            return;
        }
        const timestamp = firestore_1.FieldValue.serverTimestamp();
        const userDoc = {
            uid, role, email: email || '', phone: phone || '', name, profile_picture_url: '', address: address || '',
            created_at: timestamp, updated_at: timestamp, is_active: true, language_preference: language_preference || 'en'
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