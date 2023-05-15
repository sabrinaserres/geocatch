const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const jwt = require('jsonwebtoken');
const session = require('express-session');
const cors = require('cors');


const app = express();

// Connexion à la base de données MongoDB
mongoose.connect('mongodb://localhost/geocaching', {
  useNewUrlParser: true,
  useUnifiedTopology: true
});
mongoose.connection.on('error', (err) => {
  console.error(`Erreur de connexion à la base de données : ${err}`);
});
mongoose.connection.once('open', () => {
  console.log('Connexion réussie à la base de données');
});

// Création du modèle pour la collection d'utilisateurs
const UserSchema = new mongoose.Schema({
  username: { type: String, unique: true, required: true },
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true }
});
const User = mongoose.model('User', UserSchema);

// Middleware pour parser les requêtes HTTP
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());


app.use(cors());

// Middleware pour les sessions
app.use(session({
  secret: 'secret',
  resave: false,
  saveUninitialized: true
}));

// Route pour ajouter un nouvel utilisateur
app.post('/api/users', async (req, res) => {
    const { username, email, password } = req.body;
  
    try {
      // Vérification si l'utilisateur existe déjà avec le même username ou email
      const user = await User.findOne({ $or: [{ username }, { email }] });
  
      if (user) {
        console.error(`L'utilisateur avec le même username ou email existe déjà`);
        res.status(400).json({ message: 'Username ou email déjà existant' });
      } else {
        // Création d'un nouvel utilisateur
        const newUser = new User({ username, email, password });
        await newUser.save();
  
        console.log(`Nouvel utilisateur enregistré : ${newUser}`);
        res.status(200).json({ message: 'Utilisateur enregistré avec succès' });
      }
    } catch (err) {
      console.error(`Erreur d'enregistrement d'utilisateur : ${err}`);
      res.status(500).json({ message: 'Erreur interne du serveur' });
    }
  });



// Route pour authentifier un utilisateur
app.post('/api/users/authenticate', async (req, res) => {
  const { username, password } = req.body;

  try {
    // Vérification si l'utilisateur existe dans la base de données
    const user = await User.findOne({ username, password });

    if (user) {
      console.log(`Utilisateur ${username} connecté`);

      // Générer un token JWT avec une durée de validité de 1 heure
      const token = jwt.sign({ username }, 'secret', { expiresIn: '1h' });

      // Stocker le token dans la session de l'utilisateur
      req.session.token = token;

      // Renvoyer le token dans la réponse
      res.status(200).json({ message: 'Connexion réussie', token });
    } else {
      console.error(`Identifiants de connexion invalides pour l'utilisateur ${username}`);
      res.status(401).json({ message: 'Identifiants de connexion invalides' });
    }
  } catch (err) {
    console.error(`Erreur d'authentification de l'utilisateur ${username} : ${err}`);
    res.status(500).json({ message: 'Erreur interne du serveur' });
  }
});

// Route pour déconnecter un utilisateur
app.post('/api/users/logout', (req, res) => {
  try {
    // Supprimer le token de l'utilisateur des données de session
    req.session.token = null;
    console.log(`Utilisateur déconnecté`);

    // Renvoyer une réponse réussie
    res.status(200).json({ message: 'Déconnexion réussie' });
  } catch (err) {
    console.error(`Erreur lors de la déconnexion de l'utilisateur : ${err}`);
    res.status(500).json({ message: 'Erreur interne du serveur' });
  }
});

// Middleware pour vérifier si l'utilisateur est authentifié
const authenticateUser = (req, res, next) => {
  // Récupérer le token JWT de la session de l'utilisateur
  const token = req.session.token;

  if (token) {
    // Vérifier la validité du token JWT
    jwt.verify(token, 'secret', (err, decodedToken) => {
      if (err) {
        console.error(`Erreur de vérification du token JWT : ${err}`);
        res.status(401).json({ message: 'Token JWT invalide' });
      } else {
        console.log(`Utilisateur ${decodedToken.username} authentifié`);
        next();
      }
    });
  } else {
    console.error(`Token JWT manquant`);
    res.status(401).json({ message: 'Authentification requise' });
  }
};

//schema caches

const CacheSchema = new mongoose.Schema({
  longitude: { type: Number, required: true },
  latitude: { type: Number, required: true },
  difficulty: { type: Number, required: true },
  description: { type: String },
  creator: { type: String, required: true }
});

const Cache = mongoose.model('Cache', CacheSchema);

// route pour add une cache

app.post('/api/caches', authenticateUser, async (req, res) => {
  try {
    const cache = new Cache({
      latitude: req.body.latitude,
      longitude: req.body.longitude,
      creator: req.body.username,
      difficulty: req.body.difficulty,
      description: req.body.description
    });

    const newCache = await cache.save();

    console.log("New hiding spot: ", newCache);

    res.status(201).json({ message: 'Cache created successfully' });
  } catch (error) {
    console.error(error);
    res.status(400).json({ message: 'Error creating cache' });
  }
});




  

// Lancement du serveur sur le port 3000
app.listen(3000, () => {
  console.log('Serveur lancé sur le port 3000');
});
