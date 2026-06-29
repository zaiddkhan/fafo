import { getAuth } from "firebase/auth";
import { app } from "@/firebase";

// Attach Firebase Auth to the website's existing app instance so the admin
// panel and the public site share a single Firebase app. Importing
// `firebase/auth` here (not in the shared module) keeps it out of the landing
// bundle — only the lazy-loaded /admin chunk pulls it in.
export const auth = getAuth(app);
