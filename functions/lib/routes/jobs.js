"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.jobsRouter = void 0;
const express_1 = require("express");
const firestore_1 = require("firebase-admin/firestore");
const middlewares_1 = require("../middlewares");
exports.jobsRouter = (0, express_1.Router)();
// Haversine distance helper function
function generateOTP() {
    return Math.floor(1000 + Math.random() * 9000).toString();
}
function getDistanceFromLatLonInKm(lat1, lon1, lat2, lon2) {
    const R = 6371; // Radius of the earth in km
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
}
exports.jobsRouter.post('/create', middlewares_1.authenticateUser, (0, middlewares_1.requireRole)(['customer']), async (req, res, next) => {
    try {
        const { service_type, service_rate, location } = req.body;
        const jobRef = req.db.collection('jobs').doc();
        const otp = generateOTP();
        const newJob = {
            job_id: jobRef.id, customer_id: req.user.uid, assigned_worker_id: null,
            service_type, service_rate, location, status: 'open', otp: otp,
            created_at: firestore_1.FieldValue.serverTimestamp(), updated_at: firestore_1.FieldValue.serverTimestamp(),
            completed_at: null, customer_rating: null,
            worker_rating: null, payment_status: 'pending'
        };
        await jobRef.set(newJob);
        // Broadcast Logging
        // Query active workers to calculate target_worker_count
        let targetWorkerCount = 0;
        if (service_type) {
            const workersSnap = await req.db.collection('workers').where('service_category', '==', service_type).get();
            targetWorkerCount = workersSnap.size;
        }
        const broadcastLogRef = req.db.collection('broadcast_logs').doc();
        await broadcastLogRef.set({
            log_id: broadcastLogRef.id,
            job_id: jobRef.id,
            created_at: newJob.created_at,
            broadcast_timestamp: firestore_1.FieldValue.serverTimestamp(),
            target_worker_count: targetWorkerCount
        });
        res.status(201).json({ status: 'success', data: newJob });
    }
    catch (error) {
        next(error);
    }
});
exports.jobsRouter.get('/list', middlewares_1.authenticateUser, async (req, res, next) => {
    try {
        const { status, limit, latitude, longitude, radius } = req.query;
        // Haversine Validation
        if (latitude || longitude || radius) {
            if (!latitude || !longitude) {
                res.status(400).json({ code: 'bad-request', message: 'Both latitude and longitude are required for location filtering.' });
                return;
            }
        }
        const lat = parseFloat(latitude);
        const lng = parseFloat(longitude);
        const rad = parseFloat(radius) || 10; // Default 10km radius
        let query = req.db.collection('jobs');
        if (status)
            query = query.where('status', '==', status);
        query = query.orderBy('created_at', 'desc').limit(Number(limit) || 50);
        const snapshot = await query.get();
        let jobs = snapshot.docs.map((doc) => doc.data());
        // Perform memory-layer spatial filtering and sorting
        if (latitude && longitude) {
            jobs = jobs.map((job) => {
                if (job.location && job.location.latitude && job.location.longitude) {
                    const dist = getDistanceFromLatLonInKm(lat, lng, job.location.latitude, job.location.longitude);
                    return Object.assign(Object.assign({}, job), { distance_km: dist });
                }
                return Object.assign(Object.assign({}, job), { distance_km: 999999 }); // Unknown location pushed to back
            });
            // Filter by radius
            jobs = jobs.filter((job) => job.distance_km <= rad);
            // Sort by distance ASC
            jobs.sort((a, b) => a.distance_km - b.distance_km);
        }
        res.status(200).json({ status: 'success', data: jobs });
    }
    catch (error) {
        next(error);
    }
});
exports.jobsRouter.post('/:id/accept', middlewares_1.authenticateUser, (0, middlewares_1.requireRole)(['worker']), async (req, res, next) => {
    try {
        const jobId = req.params.id;
        const workerId = req.user.uid;
        const jobRef = req.db.collection('jobs').doc(jobId);
        await req.db.runTransaction(async (transaction) => {
            var _a;
            const jobDoc = await transaction.get(jobRef);
            if (!jobDoc.exists)
                throw new Error('Job not found');
            if (((_a = jobDoc.data()) === null || _a === void 0 ? void 0 : _a.status) !== 'open')
                throw new Error('Job is no longer open');
            transaction.update(jobRef, { status: 'assigned', assigned_worker_id: workerId, updated_at: firestore_1.FieldValue.serverTimestamp() });
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
exports.jobsRouter.post('/:id/complete', middlewares_1.authenticateUser, (0, middlewares_1.requireRole)(['worker']), async (req, res, next) => {
    try {
        const jobId = req.params.id;
        const { otp } = req.body;
        const workerId = req.user.uid;
        if (!otp) {
            res.status(400).json({ code: 'MISSING_OTP', message: 'OTP is required to complete the job' });
            return;
        }
        let workerEarnings = 0;
        let welfareContribution = 0;
        await req.db.runTransaction(async (transaction) => {
            const jobRef = req.db.collection('jobs').doc(jobId);
            const jobDoc = await transaction.get(jobRef);
            if (!jobDoc.exists)
                throw new Error('Job not found');
            const jobData = jobDoc.data();
            if (jobData.status !== 'assigned')
                throw new Error(`Job is not assigned. Current status: ${jobData.status}`);
            if (jobData.assigned_worker_id !== workerId)
                throw new Error('This job is not assigned to you');
            if (jobData.otp !== otp)
                throw new Error('Incorrect OTP');
            const serviceRate = jobData.service_rate || 0;
            workerEarnings = serviceRate * 0.97;
            welfareContribution = serviceRate * 0.03;
            // 1. Update Job
            transaction.update(jobRef, {
                status: 'completed',
                completed_at: firestore_1.FieldValue.serverTimestamp(),
                payment_status: 'completed',
                worker_earnings: workerEarnings,
                welfare_contribution: welfareContribution,
            });
            // 2. Update Worker
            const workerRef = req.db.collection('workers').doc(workerId);
            const workerDoc = await transaction.get(workerRef);
            if (workerDoc.exists) {
                const wData = workerDoc.data();
                transaction.update(workerRef, {
                    total_earnings: (wData.total_earnings || 0) + workerEarnings,
                    today_earnings: (wData.today_earnings || 0) + workerEarnings,
                    total_jobs_completed: (wData.total_jobs_completed || 0) + 1,
                });
            }
            // 3. Update Platform Stats
            const statsRef = req.db.collection('platform').doc('stats');
            const statsDoc = await transaction.get(statsRef);
            if (statsDoc.exists) {
                const sData = statsDoc.data();
                transaction.update(statsRef, {
                    total_revenue: (sData.total_revenue || 0) + serviceRate,
                    welfare_fund_balance: (sData.welfare_fund_balance || 0) + welfareContribution,
                    total_jobs_completed: (sData.total_jobs_completed || 0) + 1,
                });
            }
            else {
                transaction.set(statsRef, {
                    total_revenue: serviceRate,
                    welfare_fund_balance: welfareContribution,
                    total_jobs_completed: 1,
                    total_jobs_created: 1, // Approximation
                    active_workers: 1,
                    verified_workers: 1,
                    created_at: firestore_1.FieldValue.serverTimestamp(),
                });
            }
            // 4. Log Transaction
            const transactionLogRef = req.db.collection('transactions').doc();
            transaction.set(transactionLogRef, {
                job_id: jobId,
                worker_id: workerId,
                customer_id: jobData.customer_id,
                service_type: jobData.service_type,
                service_rate: serviceRate,
                worker_earnings: workerEarnings,
                welfare_contribution: welfareContribution,
                transaction_status: 'completed',
                completed_at: firestore_1.FieldValue.serverTimestamp(),
            });
        });
        res.status(200).json({
            code: 'JOB_COMPLETED',
            data: {
                job_id: jobId,
                worker_earnings: workerEarnings,
                welfare_contribution: welfareContribution,
                message: 'Job completed! You earned Rs ' + workerEarnings.toFixed(2) + '. Cooperative fund received Rs ' + welfareContribution.toFixed(2)
            }
        });
    }
    catch (error) {
        if (error.message.includes('not found') || error.message.includes('Incorrect OTP') || error.message.includes('not assigned')) {
            res.status(400).json({ code: 'VALIDATION_ERROR', message: error.message });
            return;
        }
        next(error);
    }
});
//# sourceMappingURL=jobs.js.map