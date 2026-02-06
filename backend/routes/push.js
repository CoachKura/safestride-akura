const express = require("express");
const router = express.Router();
const { supabase } = require("../config/supabase");

// Simple stub to save push subscriptions
router.post("/subscribe", async (req, res) => {
  try {
    const { subscription } = req.body;
    if (!subscription)
      return res.status(400).json({ error: "No subscription provided" });

    // Try to persist in Supabase table 'push_subscriptions' if exists
    try {
      const { data, error } = await supabase
        .from("push_subscriptions")
        .insert([{ subscription, created_at: new Date().toISOString() }]);
      if (error) {
        console.warn("Could not save subscription to DB:", error.message);
      }
    } catch (e) {
      console.warn("Supabase insert failed for subscription:", e.message);
    }

    return res.status(201).json({ status: "ok" });
  } catch (error) {
    console.error("Subscribe error:", error);
    return res.status(500).json({ error: "Internal error" });
  }
});

router.post("/unsubscribe", async (req, res) => {
  try {
    const { endpoint } = req.body;
    if (!endpoint)
      return res.status(400).json({ error: "No endpoint provided" });

    try {
      const { data, error } = await supabase
        .from("push_subscriptions")
        .delete()
        .eq("subscription->>endpoint", endpoint);
      if (error) console.warn("Could not delete subscription:", error.message);
    } catch (e) {
      console.warn("Supabase delete failed for subscription:", e.message);
    }

    return res.status(200).json({ status: "ok" });
  } catch (error) {
    console.error("Unsubscribe error:", error);
    return res.status(500).json({ error: "Internal error" });
  }
});

module.exports = router;
