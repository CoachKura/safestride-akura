// AKURA SafeStride Backend API
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 10000;

// Middleware
app.use(helmet());
app.use(cors({
  origin: [
    process.env.FRONTEND_URL,
    'https://akura.in',
    'https://www.akura.in',
    'https://safeastride.netlify.app',
    'http://localhost:5500',
    'http://localhost:8080'
  ],
  credentials: true
}));
app.use(express.json());
app.use(morgan('combined'));

// Initialize Supabase (before routes)
const { supabase } = require('./config/supabase');

// ============================================================================
// HEALTH CHECK & TEST ROUTES
// ============================================================================

// Health check endpoint
app.get('/healthz', (req, res) => {
  res.json({ 
    status: 'ok',
    service: 'SafeStride by AKURA Backend',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Test Supabase database connection
app.get('/api/test/db', async (req, res) => {
  try {
    // Simple query to test connection
    const { data, error } = await supabase
      .from('profiles')
      .select('id')
      .limit(1);
    
    if (error) {
      console.error('Database test error:', error);
      throw error;
    }
    
    res.json({ 
      status: 'ok', 
      message: 'Database connection successful',
      supabase: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Database connection failed:', error);
    res.status(500).json({ 
      status: 'error', 
      message: 'Database connection failed',
      error: error.message 
    });
  }
});

// ============================================================================
// API ROUTES
// ============================================================================

// Mount route handlers
try {
  app.use('/api/auth', require('./routes/auth'));
  app.use('/api/assessments', require('./routes/assessments'));
  app.use('/api/protocols', require('./routes/protocols'));
  app.use('/api/workouts', require('./routes/workouts'));
  console.log('✅ All routes loaded successfully');
} catch (error) {
  console.error('❌ Failed to load routes:', error.message);
}

// ============================================================================
// ERROR HANDLING
// ============================================================================

// 404 handler (must be after all routes)
app.use((req, res) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: 'Route not found',
      path: req.path,
      requestId: `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    }
  });
});

// Global error handler (must be last)
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(err.status || 500).json({
    error: {
      code: err.code || 'INTERNAL_ERROR',
      message: err.message || 'Something went wrong',
      requestId: `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    }
  });
});

// ============================================================================
// START SERVER
// ============================================================================

app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 SafeStride Backend Server');
  console.log(`📍 Running on http://localhost:${PORT}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`⏰ Started at: ${new Date().toISOString()}`);
});

module.exports = app;
