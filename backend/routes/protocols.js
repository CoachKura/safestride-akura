const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

router.get('/:id', async (req, res) => {
  try {
    const { data, error } = await supabase.from('protocols').select('*').eq('id', req.params.id).single();
    if (error) throw error;
    res.json(data);
  } catch (error) {
    res.status(404).json({ error: { code: 'PROTOCOL_NOT_FOUND', message: error.message } });
  }
});

router.post('/', async (req, res) => {
  try {
    const { data, error } = await supabase.from('protocols').insert({
      athlete_id: req.body.athleteId,
      name: req.body.name || 'AKURA 90-Day Plan',
      protocol_data: req.body.protocolData || {},
      status: 'active'
    }).select().single();
    if (error) throw error;
    res.status(201).json({ protocolId: data.id });
  } catch (error) {
    res.status(500).json({ error: { code: 'PROTOCOL_CREATE_FAILED', message: error.message } });
  }
});

module.exports = router;
