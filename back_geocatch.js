// Import des modules nécessaires
const express = require('express');

const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

// Initialisation de l'application Express
const app = express();
app.listen(3000, () => console.log('Server started on port 3000'));
// Connexion à la base de données MongoDB
mongoose.connect('mongodb://localhost/geocaching', {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

// Schéma de la collection des utilisateurs
const userSchema = new mongoose.Schema({
  email: { type: String, unique: true },
  password: String
});

// Modèle de la collection des utilisateurs
const User = mongoose.model('User', userSchema);

// Schéma de la collection des geocaches
const cacheSchema = new mongoose.Schema({
  id: { type: String, unique: true },
  coordinates: {
    latitude: Number,
    longitude: Number
  },
  creator: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  difficulty: Number,
  description: String
});

// Modèle de la collection des geocaches
const Cache = mongoose.model('Cache', cacheSchema);

// Middleware pour parser les données JSON dans les requêtes
app.use(bodyParser.json());

// Middleware pour gérer les erreurs de validation des données
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).json({ message: 'Invalid JSON data' });
  }
  next();
});

// Middleware pour vérifier l'authentification de l'utilisateur
const authenticateUser = (req, res, next) => {
  const token = req.headers.authorization;
  if (!token) {
    return res.status(401).json({ message: 'Missing authorization token' });
  }
  jwt.verify(token, 'secret', (err, decoded) => {
    if (err) {
      return res.status(401).json({ message: 'Invalid authorization token' });
    }
    req.user = decoded;
    next();
  });
};

// Endpoint pour créer un nouvel utilisateur
app.post('/api/users', async (req, res) => {
  try {
    const user = new User({
      email: req.body.email,
      password: req.body.password
    });
    await user.save();
    res.status(201).json({ message: 'User created successfully' });
  } catch (error) {
    res.status(400).json({ message: 'Error creating user' });
  }
});

// Endpoint pour authentifier un utilisateur et générer un token
app.post('/api/authenticate', async (req, res) => {
  try {
    const user = await User.findOne({ email: req.body.email });
    if (!user || user.password !== req.body.password) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    const token = jwt.sign({ id: user._id }, 'secret', { expiresIn: '24h' });
    res.json({ token });
  } catch (error) {
    res.status(400).json({ message: 'Error authenticating user' });
  }
});

// Endpoint pour créer une nouvelle géocache
app.post('/api/caches', authenticateUser, async (req, res) => {
  try {
    const cache = new Cache({
      id: req.body.id,
      coordinates: {
        latitude: req.body.latitude,
        longitude: req.body.longitude
      },
      creator: req.user.id,
      difficulty: req.body.difficulty,
      description: req.body.description
    });
    await cache.save();
    res.status(201).json({ message: 'Cache created successfully' });
  } catch (error) {
    res.status(400).json({ message: 'Error creating cache' });
  }
});
// Endpoint pour récupérer une géocache
app.get('/api/caches/:id', authenticateUser, async (req, res) => {
  try {
    const cache = await Cache.findOne({ id: req.params.id }).populate('creator', 'email');
    if (!cache) {
      return res.status(404).json({ message: 'Cache not found' });
    }
    res.json({
      id: cache.id,
      latitude: cache.coordinates.latitude,
      longitude: cache.coordinates.longitude,
      creator: cache.creator.email,
      difficulty: cache.difficulty,
      description: cache.description
    });
  } catch (error) {
    res.status(400).json({ message: 'Error getting cache' });
  }
});
// Endpoint pour récupérer toutes les géocaches
app.get('/api/caches', authenticateUser, async (req, res) => {
  try {
    const caches = await Cache.find().populate('creator', 'email');
    res.json(caches.map(cache => ({
      id: cache.id,
      latitude: cache.coordinates.latitude,
      longitude: cache.coordinates.longitude,
      creator: cache.creator.email,
      difficulty: cache.difficulty,
      description: cache.description
    })));
  } catch (error) {
    res.status(400).json({ message: 'Error getting caches' });
  }
});
// Endpoint pour mettre à jour une géocache
app.put('/api/caches/:id', authenticateUser, async (req, res) => {
  try {
    const cache = await Cache.findOne({ id: req.params.id, creator: req.user.id });
    if (!cache) {
      return res.status(404).json({ message: 'Cache not found' });
    }
    cache.coordinates.latitude = req.body.latitude;
    cache.coordinates.longitude = req.body.longitude;
    cache.difficulty = req.body.difficulty;
    cache.description = req.body.description;
    await cache.save();
    res.json({ message: 'Cache updated successfully' });
  } catch (error) {
    res.status(400).json({ message: 'Error updating cache' });
  }
});

// Endpoint pour supprimer une géocache
app.delete('/api/caches/:id', authenticateUser, async (req, res) => {
  try {
    const cache = await Cache.findOne({ id: req.params.id, creator: req.user.id });
    if (!cache) {
      return res.status(404).json({ message: 'Cache not found' });
    }
    await cache.remove();
    res.json({ message: 'Cache deleted successfully' });
  } catch (error) {
    res.status(400).json({ message: 'Error deleting cache' });
  }
});

// Endpoint pour mettre à jour les informations de l'utilisateur
app.put('/api/users/:id', authenticateUser, async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    user.email = req.body.email;
    user.password = req.body.password;
    await user.save();
    res.json({ message: 'Cache deleted successfully' });
  } catch (error) {
    res.status(400).json({ message: 'Error deleting cache' });
  }g()
  app.listen(2800, () => {
    console.log("En attente de requêtes...")
  })
});