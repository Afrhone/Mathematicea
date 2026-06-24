import crypto from 'crypto';

const key = crypto.randomBytes(32).toString('base64');
console.log('CUSTODY_MASTER_KEY_B64=' + key);
