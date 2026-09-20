"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminRouter = void 0;
const express_1 = require("express");
const middlewares_1 = require("../middlewares");
exports.adminRouter = (0, express_1.Router)();
exports.adminRouter.post('/workers/:id/approve', middlewares_1.authenticateUser, (0, middlewares_1.requireRole)(['admin']), async (req, res, next) => {
    try {
        const workerId = req.params.id;
        const workerRef = req.db.collection('workers').doc(workerId);
        const workerDoc = await workerRef.get();
        if (!workerDoc.exists) {
            res.status(404).json({ code: 'not-found', message: 'Worker profile not found.' });
            return;
        }
        await workerRef.update({
            verification_status: 'approved',
            national_id_verified: true,
            updated_at: new Date()
        });
        res.status(200).json({ status: 'success', message: 'Worker approved successfully.' });
    }
    catch (error) {
        next(error);
    }
});
exports.adminRouter.get('/dashboard/stats', middlewares_1.authenticateUser, (0, middlewares_1.requireRole)(['admin']), async (req, res, next) => {
    try {
        const statsDoc = await req.db.collection('platform').doc('stats').get();
        const verifiedSnap = await req.db.collection('workers').where('verification_status', '==', 'approved').count().get();
        const verifiedCount = verifiedSnap.data().count;
        const pendingSnap = await req.db.collection('workers').where('verification_status', '==', 'pending').count().get();
        const pendingCount = pendingSnap.data().count;
        const activeSnap = await req.db.collection('jobs').where('status', '==', 'assigned').count().get();
        const activeJobs = activeSnap.data().count;
        if (!statsDoc.exists) {
            res.status(200).json({
                status: 'success',
                data: {
                    verified_workers: verifiedCount,
                    pending_workers: pendingCount,
                    total_jobs: 0,
                    completed_jobs: 0,
                    total_revenue: 0,
                    welfare_fund_balance: 0,
                    active_workers: verifiedCount,
                    active_jobs: activeJobs,
                }
            });
            return;
        }
        const statsData = statsDoc.data();
        res.status(200).json({
            status: 'success',
            data: {
                verified_workers: verifiedCount,
                pending_workers: pendingCount,
                total_jobs: statsData.total_jobs_created || 0,
                completed_jobs: statsData.total_jobs_completed || 0,
                total_revenue: statsData.total_revenue || 0,
                welfare_fund_balance: statsData.welfare_fund_balance || 0,
                active_workers: verifiedCount,
                active_jobs: activeJobs,
            }
        });
    }
    catch (error) {
        next(error);
    }
});
//# sourceMappingURL=admin.js.map