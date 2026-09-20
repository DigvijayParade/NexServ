const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';

const app = initializeApp({ projectId: 'nexserv-6d881' });
const auth = getAuth(app);
const db = getFirestore(app);

async function run() {
  console.log("=== STARTING VERIFICATION ===");
  try {
    // 1. Setup Test Users
    console.log("Setting up test users...");
    await auth.createUser({uid: 'test_admin', email: 'admin@test.com', password: 'password'}).catch(e => {});
    await auth.createUser({uid: 'test_customer', email: 'cust@test.com', password: 'password'}).catch(e => {});
    
    await db.collection('users').doc('test_admin').set({role: 'admin'});
    await db.collection('users').doc('test_customer').set({role: 'customer'});

    async function getIdToken(uid) {
      const customToken = await auth.createCustomToken(uid);
      const res = await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=fake', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token: customToken, returnSecureToken: true })
      });
      const data = await res.json();
      return data.idToken;
    }

    const adminToken = await getIdToken('test_admin');
    const custToken = await getIdToken('test_customer');

    // 2. Test Admin Stats Endpoint
    console.log("\n[Test] Admin Stats Endpoint as Customer (Expecting 403)");
    const statsResBad = await fetch('http://127.0.0.1:5001/nexserv-6d881/us-central1/api/api/admin/dashboard/stats', {
      headers: { 'Authorization': 'Bearer ' + custToken }
    });
    console.log("Customer Stats Response Code: " + statsResBad.status); // Should be 403

    console.log("\n[Test] Admin Stats Endpoint as Admin (Expecting 200)");
    const statsResGood = await fetch('http://127.0.0.1:5001/nexserv-6d881/us-central1/api/api/admin/dashboard/stats', {
      headers: { 'Authorization': 'Bearer ' + adminToken }
    });
    console.log("Admin Stats Response Code: " + statsResGood.status); // Should be 200
    console.log("Stats Data:", await statsResGood.json());

    // 3. Test Job Creation and Broadcast Logging
    console.log("\n[Test] Job Creation & Broadcast Logging");
    const jobRes = await fetch('http://127.0.0.1:5001/nexserv-6d881/us-central1/api/api/jobs/create', {
      method: 'POST',
      headers: { 'Authorization': 'Bearer ' + custToken, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        service_type: 'Plumber',
        service_rate: 500,
        location: { latitude: 28.7041, longitude: 77.1025, address: 'Delhi' }
      })
    });
    const jobData = await jobRes.json();
    console.log("Job Created:", jobData.data?.job_id);

    // Verify broadcast log exists in DB
    const logsSnap = await db.collection('broadcast_logs').where('job_id', '==', jobData.data.job_id).get();
    console.log("Broadcast Logs found in DB for this job:", logsSnap.size);
    if (!logsSnap.empty) {
      console.log("Log Data:", logsSnap.docs[0].data());
    }

    // 4. Test Haversine Distance (Job List)
    console.log("\n[Test] Haversine Distance Job Filter");
    // Requesting from Noida (28.5355, 77.3910) -> Should calculate distance to Delhi (28.7041, 77.1025) (approx 33km)
    const listRes = await fetch('http://127.0.0.1:5001/nexserv-6d881/us-central1/api/api/jobs/list?latitude=28.5355&longitude=77.3910&radius=50', {
      headers: { 'Authorization': 'Bearer ' + custToken }
    });
    const listData = await listRes.json();
    console.log("Jobs found near Noida within 50km:", listData.data.length);
    if (listData.data.length > 0) {
      console.log("Closest Job Distance (km):", listData.data[0].distance_km);
    }
    
    console.log("\n=== VERIFICATION COMPLETE ===");
    process.exit(0);
  } catch (e) {
    console.error("Test Error:", e);
    process.exit(1);
  }
}

run();
