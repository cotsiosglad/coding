// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
    apiKey: "AIzaSyAN2Ulodo7Vm3H76s1v0PpNSVfshkVP3ds",
    authDomain: "adminpanel-1f825.firebaseapp.com",
    projectId: "adminpanel-1f825",
    storageBucket: "adminpanel-1f825.appspot.com",
    messagingSenderId: "508520831984",
    appId: "1:508520831984:web:1a9216ca63bbb9939bdb35",
    measurementId: "G-8L5DKNV32R"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);