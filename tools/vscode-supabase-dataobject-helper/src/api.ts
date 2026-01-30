import { DataObject, DataObjectOptions, SupabaseConfig } from './types';

// Minimal in-memory store for created data objects (stubbed reactive behavior)
const store = new Map<string, DataObject>();

export async function createDataObject(config: SupabaseConfig, opts: DataObjectOptions): Promise<DataObject> {
  const id = `${opts.viewName}`;
  const listeners: Array<(d: any[]) => void> = [];
  let data: any[] = [];

  const object: DataObject = {
    id,
    getData() { return data.slice(); },
    onDataChanged(cb) { listeners.push(cb); },
    async insert(obj) {
      // naive insert: push and notify
      const rec = { ...obj, _local_id: Date.now() };
      data.push(rec);
      listeners.forEach(l => l(data.slice()));
      return rec;
    },
    async update(key, changes) {
      const idx = data.findIndex(r => r.id === key || r._local_id === key);
      if (idx === -1) throw new Error('Not found');
      data[idx] = { ...data[idx], ...changes };
      listeners.forEach(l => l(data.slice()));
      return data[idx];
    },
    async delete(key) {
      const idx = data.findIndex(r => r.id === key || r._local_id === key);
      if (idx === -1) throw new Error('Not found');
      const removed = data.splice(idx, 1)[0];
      listeners.forEach(l => l(data.slice()));
      return removed;
    },
    async refresh() {
      // placeholder: in a real impl, fetch from Supabase using config
      listeners.forEach(l => l(data.slice()));
    },
    dispose() {
      listeners.length = 0;
      store.delete(id);
    }
  };

  store.set(id, object);
  return object;
}

export function getDataObjectById(id: string): DataObject | undefined {
  return store.get(id);
}
