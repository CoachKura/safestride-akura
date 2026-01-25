const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

// Catch startup errors
process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Import routes (wrapped in try-catch to surface module errors)
let authRoutes, coachRoutes, athleteRoutes, workoutRoutes, stravaRoutes, garminRoutes;
try {
  authRoutes = require('./routes/auth');
  coachRoutes = require('./routes/coach');
  athleteRoutes = require('./routes/athlete');
  workoutRoutes = require('./routes/workouts');
  stravaRoutes = require('./routes/strava');
  garminRoutes = require('./routes/garmin');
} catch (err) {
  console.error('❌ Failed to load routes:', err);
  process.exit(1);
}

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors({
  origin: [
    process.env.FRONTEND_URL,
    'http://localhost:5173',
    'http://localhost:3000'
  ],
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check (both /health and /api/health for convenience)
const healthHandler = (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'SafeStride by AKURA Backend',
    version: '1.0.0'
  });
};

app.get('/health', healthHandler);
app.get('/api/health', healthHandler);

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/coach', coachRoutes);
app.use('/api/athlete', athleteRoutes);
app.use('/api/workouts', workoutRoutes);
app.use('/api/strava', stravaRoutes);
app.use('/api/garmin', garminRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`\n🚀 SafeStride Backend Server`);
  console.log(`📍 Running on http://localhost:${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV}`);
  console.log(`⏰ Started at: ${new Date().toISOString()}\n`);
});

module.exports = app;
