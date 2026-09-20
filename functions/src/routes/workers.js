"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.workersRouter = void 0;
const express_1 = require("express");
const middlewares_1 = require("../middlewares");
exports.workersRouter = (0, express_1.Router)();
// GET /workers/:id/profile - Fetch worker full profile + ratings
exports.workersRouter.get('/:id/profile', middlewares_1.authenticateUser, async (req, res, next) => {
    try {
        const workerId = req.params.id;
        const workerDoc = await req.db.collection('workers').doc(workerId).get();
        if (!workerDoc.exists) {
            res.status(404).json({ code: 'not-found', message: 'Worker profile not found.' });
            return;
        }
        const workerData = workerDoc.data();
        // Hide sensitive info if requesting user is not the worker themselves or an admin
        // (Assuming we enforce this either via rules or here in the API)
        if (req.user.uid !== workerId) {
            delete workerData?.bank_account;
            delete workerData?.aadhaar_id;
        }
        res.status(200).json({ status: 'success', data: workerData });
    }
    catch (error) {
        next(error);
    }
});
//# sourceMappingURL=workers.js.map