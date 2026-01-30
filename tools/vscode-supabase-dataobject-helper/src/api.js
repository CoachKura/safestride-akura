// Minimal JS implementation of createDataObject (in-memory, reactive stub)
const store = new Map();

async function createDataObject(config, opts) {
  const id = String(opts.viewName || 'unknown');
  const listeners = [];
  let data = [];

  const object = {
    id,
    getData() { return data.slice(); },
    onDataChanged(cb) { listeners.push(cb); },
    async insert(obj) {
      const rec = Object.assign({}, obj, { _local_id: Date.now() });
      data.push(rec);
      listeners.forEach(l => { try { l(data.slice()); } catch (e) {} });
      return rec;
    },
    async update(key, changes) {
      const idx = data.findIndex(r => r.id === key || r._local_id === key);
      if (idx === -1) throw new Error('Not found');
      data[idx] = Object.assign({}, data[idx], changes);
      listeners.forEach(l => { try { l(data.slice()); } catch (e) {} });
      return data[idx];
    },
    async delete(key) {
      const idx = data.findIndex(r => r.id === key || r._local_id === key);
      if (idx === -1) throw new Error('Not found');
      const removed = data.splice(idx, 1)[0];
      listeners.forEach(l => { try { l(data.slice()); } catch (e) {} });
      return removed;
    },
    async refresh() {
      // Placeholder: in real impl, fetch from Supabase using config and opts
      listeners.forEach(l => { try { l(data.slice()); } catch (e) {} });
    },
    dispose() {
      listeners.length = 0;
      store.delete(id);
    }
  };

  store.set(id, object);
  return object;
}

function getDataObjectById(id) {
  return store.get(id);
}

module.exports = { createDataObject, getDataObjectById };
