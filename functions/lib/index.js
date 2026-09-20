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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.api = void 0;
const functions = __importStar(require("firebase-functions"));
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
// Initialize Firebase Admin with Service Account if present (for Render/External servers)
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    try {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        (0, app_1.initializeApp)({
            credential: (0, app_1.cert)(serviceAccount)
        });
    }
    catch (e) {
        console.error("Failed to parse FIREBASE_SERVICE_ACCOUNT env var, falling back to default:", e);
        (0, app_1.initializeApp)();
    }
}
else {
    (0, app_1.initializeApp)();
}
const db = (0, firestore_1.getFirestore)();
const auth_1 = require("./routes/auth");
const jobs_1 = require("./routes/jobs");
const workers_1 = require("./routes/workers");
const admin_1 = require("./routes/admin");
const middlewares_1 = require("./middlewares");
const app = (0, express_1.default)();
app.use((0, cors_1.default)({ origin: true }));
app.use(express_1.default.json());
app.use((req, res, next) => {
    req.db = db;
    next();
});
app.use('/api/auth', auth_1.authRouter);
app.use('/api/jobs', jobs_1.jobsRouter);
app.use('/api/workers', workers_1.workersRouter);
app.use('/api/admin', admin_1.adminRouter);
app.use(middlewares_1.errorHandler);
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`NexServ backend API server running on port ${PORT}`);
});
exports.api = functions.https.onRequest(app);
//# sourceMappingURL=index.js.map