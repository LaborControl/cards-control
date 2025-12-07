import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { googleWalletRouter } from './routes/google-wallet';
import { appleWalletRouter } from './routes/apple-wallet';
import { cardsRouter } from './routes/cards';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
  origin: [
    'https://cards-control.app',
    'https://api.cards-control.app',
    /localhost/,
  ],
}));
app.use(express.json());

// Routes
app.use('/wallet/google', googleWalletRouter);
app.use('/wallet/apple', appleWalletRouter);
app.use('/cards', cardsRouter);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Error handler
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  console.log(`🚀 NFC Pro Backend running on port ${PORT}`);
});
