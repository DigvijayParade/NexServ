"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.adminRouter = void 0;
const express_1 = require("express");
const middlewares_1 = require("../middlewares");
exports.adminRouter = (0, express_1.Router)();
// POST /admin/workers/:id/approve - Admin approves worker verification
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
//# sourceMappingURL=admin.js.map