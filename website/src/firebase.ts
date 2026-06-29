import { initializeApp } from 'firebase/app'
import { getFirestore } from 'firebase/firestore'

// Web app config for Firebase project `fafu-869a8` (the "fafu (web)" app).
// These values are safe to ship in client code; access is governed by
// Firestore security rules (see backend/firestore.rules — the `waitlist`
// collection allows create-only from the public web).
const firebaseConfig = {
  apiKey: 'AIzaSyCM6ygl65A4YFK6qZ_8vqEgttSlgN3aA8A',
  authDomain: 'fafu-869a8.firebaseapp.com',
  projectId: 'fafu-869a8',
  storageBucket: 'fafu-869a8.firebasestorage.app',
  messagingSenderId: '149624228243',
  appId: '1:149624228243:web:7d8888372c8bc6c448c066',
  measurementId: 'G-HGMT9DWMS0',
}

// Exported so the /admin panel can attach Firebase Auth to the same app
// instance (see src/admin/lib/firebase.ts) without initializing Firebase twice.
export const app = initializeApp(firebaseConfig)
export const db = getFirestore(app)
