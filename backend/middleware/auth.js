const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

/**
 * Generate JWT token
 */
function generateToken(payload) {
  return jwt.sign(payload, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN
  });
}

/**
 * Verify JWT token
 */
function verifyToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    return null;
  }
}

/**
 * Authentication middleware for coaches
 */
function authenticateCoach(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  const token = authHeader.substring(7);
  const decoded = verifyToken(token);
  
  if (!decoded || decoded.role !== 'coach') {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
  
  req.coachId = decoded.id;
  req.coachEmail = decoded.email;
  next();
}

/**
 * Authentication middleware for athletes
 */
function authenticateAthlete(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  const token = authHeader.substring(7);
  const decoded = verifyToken(token);
  
  if (!decoded || decoded.role !== 'athlete') {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
  
  req.athleteId = decoded.id;
  req.athleteEmail = decoded.email;
  next();
}

/**
 * Authentication middleware for both coaches and athletes
 */
function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  const token = authHeader.substring(7);
  const decoded = verifyToken(token);
  
  if (!decoded) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
  
  req.userId = decoded.id;
  req.userEmail = decoded.email;
  req.userRole = decoded.role;
  next();
}

module.exports = {
  generateToken,
  verifyToken,
  authenticateCoach,
  authenticateAthlete,
  authenticate
};
