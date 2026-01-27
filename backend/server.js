// AKURA SafeStride Backend API
// Version: 1.0.0
// Last Updated: 2026-01-27

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.FRONTEND_URL || 'https://akura.in',
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Authorization', 'Content-Type', 'X-Request-Id', 'X-Client-Id', 'Idempotency-Key']
}));

// Body parsing
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request ID middleware
app.use((req, res, next) => {
  req.id = req.headers['x-request-id'] || `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  res.setHeader('X-Request-Id', req.id);
  next();
});

// Request logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path} [${req.id}]`);
  next();
});

// Health check handler (shared for all health endpoints)
const healthHandler = (req, res) => {
  res.json({
    status: 'ok',
    service: 'SafeStride by AKURA Backend',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
};

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    error: {
      code: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many requests, please try again later'
    }
  }
});
app.use('/api', limiter);

app.get('/health', healthHandler);
app.get('/healthz', healthHandler);
app.get('/api/health', healthHandler);

// Import routes
let authRoutes, assessmentRoutes, protocolRoutes, workoutRoutes;
try {
  authRoutes = require('./routes/auth');
  assessmentRoutes = require('./routes/assessments');
  protocolRoutes = require('./routes/protocols');
  workoutRoutes = require('./routes/workouts');
} catch (err) {
  console.error('❌ Failed to load routes:', err.message);
  // Create placeholder routes if files don't exist
  authRoutes = express.Router();
  authRoutes.get('/login', (req, res) => res.json({ message: 'Auth route placeholder' }));
  assessmentRoutes = express.Router();
  assessmentRoutes.post('/', (req, res) => res.json({ message: 'Assessment route placeholder' }));
  protocolRoutes = express.Router();
  protocolRoutes.get('/:id', (req, res) => res.json({ message: 'Protocol route placeholder' }));
  workoutRoutes = express.Router();
  workoutRoutes.post('/:id/feedback', (req, res) => res.json({ message: 'Workout route placeholder' }));
}

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/assessments', assessmentRoutes);
app.use('/api/protocols', protocolRoutes);
app.use('/api/workouts', workoutRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(`❌ Error [${req.id}]:`, err.stack);
  res.status(err.status || 500).json({
    error: {
      code: err.code || 'INTERNAL_ERROR',
      message: err.message || 'Something went wrong',
      requestId: req.id,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: 'Route not found',
      path: req.path,
      requestId: req.id
    }
  });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('\n🛑 SIGTERM received, shutting down gracefully...');
  process.exit(0);
});

// Start server
app.listen(PORT, () => {
  console.log(`\n🚀 SafeStride Backend Server`);
  console.log(`📍 Running on http://localhost:${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`⏰ Started at: ${new Date().toISOString()}\n`);
});

module.exports = app;
