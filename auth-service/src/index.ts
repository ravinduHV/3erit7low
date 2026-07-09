import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { toNodeHandler } from "better-auth/node";
import { auth } from "./auth";

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Configure CORS for cross-origin access (Flutter web, mobile, local)
app.use(cors({
  origin: "*",
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
  allowedHeaders: ["Content-Type", "Authorization", "Cookie"]
}));

// Express-specific route matching: mount toNodeHandler directly
// IMPORTANT: express.json() is NOT applied before this to avoid hanging the auth streams
app.all("/api/auth/*", toNodeHandler(auth));

// Apply JSON parser only for other routes
app.use(express.json());

app.get("/health", (req, res) => {
  res.json({ status: "healthy", service: "auth-proxy" });
});

app.listen(port, () => {
  console.log(`Auth proxy server running on http://localhost:${port}`);
});
