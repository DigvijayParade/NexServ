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
exports.jobsRouter = void 0;
const express_1 = require("express");
const admin = __importStar(require("firebase-admin"));
const middlewares_1 = require("../middlewares");
exports.jobsRouter = (0, express_1.Router)();
// POST /jobs/create - Create new job request from customer
exports.jobsRouter.post('/create', middlewares_1.authenticateUser, (0, middlewares_1.requireRole)(['customer']), async (req, res, next) => {
    try {
        const { service_type, service_rate, location } = req.body;
        if (!service_type || !service_rate || !location) {
            res.status(400).json({ code: 'invalid-request', message: 'Missing fields: service_type, service_rate, location' });
            return;
        }
        const jobRef = req.db.collection('jobs').doc();
        const newJob = {
            job_id: jobRef.id,
            customer_id: req.user.uid,
            assigned_worker_id: null,
            service_type,
            service_rate,
            location,
            status: 'open',
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            completed_at: null,
            customer_rating: null,
            worker_rating: null,
            payment_status: 'pending'
        };
        await jobRef.set(newJob);
        res.status(201).json({ status: 'success', data: newJob });
    }
    catch (error) {
        next(error);
    }
});
// GET /jobs/list - List jobs with filters
exports.jobsRouter.get('/list', middlewares_1.authenticateUser, async (req, res, next) => {
    try {
        const { status, limit } = req.query;
        let query = req.db.collection('jobs');
        if (status) {
            query = query.where('status', '==', status);
        }
        query = query.orderBy('created_at', 'desc').limit(Number(limit) || 20);
        const snapshot = await query.get();
        const jobs = snapshot.docs.map(doc => doc.data());
        res.status(200).json({ status: 'success', data: jobs });
    }
    catch (error) {
        next(error);
    }
});
// POST /jobs/:id/accept - Worker accepts a job
exports.jobsRouter.post('/:id/accept', middlewares_1.authenticateUser, (0, middlewares_1.requireRole)(['worker']), async (req, res, next) => {
    try {
        const jobId = req.params.id;
        const workerId = req.user.uid;
        const jobRef = req.db.collection('jobs').doc(jobId);
        await req.db.runTransaction(async (transaction) => {
            const jobDoc = await transaction.get(jobRef);
            if (!jobDoc.exists)
                throw new Error('Job not found');
            const jobData = jobDoc.data();
            if ((jobData === null || jobData === void 0 ? void 0 : jobData.status) !== 'open')
                throw new Error('Job is no longer open');
            transaction.update(jobRef, {
                status: 'assigned',
                assigned_worker_id: workerId
            });
        });
        res.status(200).json({ status: 'success', message: 'Job accepted successfully' });
    }
    catch (error) {
        if (error.message === 'Job not found' || error.message === 'Job is no longer open') {
            res.status(400).json({ code: 'job-error', message: error.message });
            return;
        }
        next(error);
    }
});
//# sourceMappingURL=jobs.js.map