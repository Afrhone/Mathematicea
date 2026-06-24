import { db } from '../lib/db.js';

db(); // triggers schema creation
console.log('DB ok.');
