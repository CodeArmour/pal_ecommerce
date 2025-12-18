import express from "express";
import { formatCurrency } from "@pal/utils";

const app = express();
const port = 3001;

const price = 19.99;
console.log(`Formatted price: ${formatCurrency(price)}`);
console.log("API is starting...");

app.get("/", (_, res) => {
  res.send("Hello from Express + TypeScript!");
});

app.listen(port, () => {
  console.log(`API running on http://localhost:${port}`);
});
