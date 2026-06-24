import express from 'express';
import dotenv from 'dotenv';
dotenv.config();
const app = express();
app.use(express.static('public'));
app.listen(Number(process.env.DASHBOARD_PORT || 7227),'0.0.0.0',()=>console.log('YETTI Codex dashboard'));
