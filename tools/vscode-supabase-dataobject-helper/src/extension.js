const vscode = require('vscode');
const api = require('./api');

/** @param {vscode.ExtensionContext} context */
function activate(context) {
  context.subscriptions.push(vscode.commands.registerCommand('supabase.openHelper', async () => {
    const panel = vscode.window.createWebviewPanel('supabaseHelper', 'Supabase Data Object Helper', vscode.ViewColumn.One, { enableScripts: true });

    panel.webview.html = getWebviewContent();

    panel.webview.onDidReceiveMessage(async (msg) => {
      if (msg.command === 'saveConfig') {
        await context.secrets.store('supabase.config', JSON.stringify(msg.config || {}));
        vscode.window.showInformationMessage('Supabase configuration saved.');
      }

      if (msg.command === 'testConnection') {
        const raw = await context.secrets.get('supabase.config');
        if (!raw) return vscode.window.showWarningMessage('No Supabase configuration found.');
        vscode.window.showInformationMessage('Supabase configuration present (manual test recommended).');
      }

      if (msg.command === 'getConfig') {
        const raw = await context.secrets.get('supabase.config');
        panel.webview.postMessage({ command: 'config', config: raw ? JSON.parse(raw) : null });
      }

      // New: load a table (check existence + sample row) and return helpful errors
      if (msg.command === 'loadTable') {
        const table = msg.table;
        const raw = await context.secrets.get('supabase.config');
        if (!raw) {
          panel.webview.postMessage({ command: 'tableError', error: 'No Supabase configuration found. Open the helper and save configuration first.' });
          return;
        }
        const cfg = JSON.parse(raw);
        try {
          const url = (cfg.url || '').replace(/\/$/, '');
          if (!url || !cfg.anonKey) {
            panel.webview.postMessage({ command: 'tableError', error: 'Supabase URL or anon key missing in configuration.' });
            return;
          }
          const endpoint = `${url}/rest/v1/${encodeURIComponent(table)}?limit=1`;
          const res = await fetch(endpoint, {
            method: 'GET',
            headers: {
              apikey: cfg.anonKey,
              Authorization: `Bearer ${cfg.anonKey}`,
              Accept: 'application/json'
            }
          });
          if (res.status === 404) {
            panel.webview.postMessage({ command: 'tableError', error: `Table '${table}' not found (404).` });
            return;
          }
          if (!res.ok) {
            const text = await res.text();
            panel.webview.postMessage({ command: 'tableError', error: `HTTP ${res.status}: ${text}` });
            return;
          }
          const json = await res.json();
          panel.webview.postMessage({ command: 'tableLoaded', table, sample: json });
        } catch (e) {
          panel.webview.postMessage({ command: 'tableError', error: e.message || String(e) });
        }
      }
      
      // Create a data object and persist a lightweight record in workspaceState
      if (msg.command === 'createDataObject') {
        const raw = await context.secrets.get('supabase.config');
        if (!raw) {
          panel.webview.postMessage({ command: 'createError', error: 'No Supabase configuration. Save configuration first.' });
          return;
        }
        const cfg = JSON.parse(raw);
        try {
          const opts = msg.opts || { viewName: msg.viewName };
          const obj = await api.createDataObject(cfg, opts);

          // store meta info in workspaceState
          const list = context.workspaceState.get('supabase.dataObjects', []);
          const meta = { id: obj.id, viewName: opts.viewName || opts.table, createdAt: new Date().toISOString(), opts };
          list.push(meta);
          await context.workspaceState.update('supabase.dataObjects', list);

          // send back updated list and an initial preview (likely empty)
          panel.webview.postMessage({ command: 'dataObjectsList', list });
          panel.webview.postMessage({ command: 'previewData', id: obj.id, data: obj.getData() });
        } catch (e) {
          panel.webview.postMessage({ command: 'createError', error: e.message || String(e) });
        }
      }

      // Return list of created data objects stored in workspaceState
      if (msg.command === 'getDataObjects') {
        const list = context.workspaceState.get('supabase.dataObjects', []);
        panel.webview.postMessage({ command: 'dataObjectsList', list });
      }

      // Return preview data for a specific data object id
      if (msg.command === 'previewData') {
        const id = msg.id;
        try {
          const obj = api.getDataObjectById(id);
          if (!obj) {
            panel.webview.postMessage({ command: 'previewData', id, data: [], warning: 'Data object not found in runtime (restart extension host to recreate).' });
            return;
          }
          panel.webview.postMessage({ command: 'previewData', id, data: obj.getData() });
        } catch (e) {
          panel.webview.postMessage({ command: 'previewData', id, data: [], error: e.message || String(e) });
        }
      }
    });
  }));

  context.subscriptions.push(vscode.commands.registerCommand('supabase.createDataObject', async () => {
    const raw = await context.secrets.get('supabase.config');
    const config = raw ? JSON.parse(raw) : null;
    if (!config) return vscode.window.showWarningMessage('No Supabase config found. Open Supabase Data Object Helper to configure.');
    const viewName = await vscode.window.showInputBox({ prompt: 'Table/View name (e.g. users)' });
    if (!viewName) return;
    const opts = { viewName };
    const obj = await api.createDataObject(config, opts);
    vscode.window.showInformationMessage(`Data object '${obj.id}' created.`);
  }));

  context.subscriptions.push(vscode.commands.registerCommand('supabase.testConnection', async () => {
    const raw = await context.secrets.get('supabase.config');
    if (!raw) return vscode.window.showWarningMessage('No Supabase configuration.');
    vscode.window.showInformationMessage('Supabase configuration present.');
  }));

  context.subscriptions.push(vscode.commands.registerCommand('supabase.clearConfig', async () => {
    await context.secrets.delete('supabase.config');
    vscode.window.showInformationMessage('Supabase configuration cleared.');
  }));
}

function deactivate() {}

function getWebviewContent() {
  return `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Supabase Data Object Helper</title>
  <style>
    body{font-family: sans-serif;padding:16px}
    label{display:block;margin-top:8px}
    input,button,textarea{width:100%;padding:8px;margin-top:6px}
    .row{display:flex;gap:8px}
    .row > *{flex:1}
  </style>
</head>
<body>
  <h2>Supabase Configuration</h2>
  <label>Supabase URL <input id="url" placeholder="https://your-project.supabase.co"/></label>
  <label>Anon Key <textarea id="anon" rows="3" placeholder="anon key"></textarea></label>
  <label>Project name (optional) <input id="name" placeholder="My Project"/></label>
  <div class="row" style="margin-top:12px">
    <button id="save">Save Configuration</button>
    <button id="test">Test Connection</button>
  </div>

  <h3 style="margin-top:18px">Check Table</h3>
  <label>Table / View name <input id="table" placeholder="public.my_table or my_table"/></label>
  <div class="row" style="margin-top:8px">
    <button id="load">Load Table</button>
    <button id="clear">Clear Config</button>
  </div>
  <div id="result" style="margin-top:12px"></div>
  
  <hr style="margin:18px 0" />
  <h3>Create Data Object</h3>
  <label>Data Object ID (identifier used in code) <input id="dataId" placeholder="myUsers"/></label>
  <label>Table / View Name <input id="tableName" placeholder="users"/></label>
  <label>Fields (comma separated) <input id="fields" placeholder="id,email,name"/></label>
  <label>Where (JSON - optional) <input id="where" placeholder='{"active":true}'/></label>
  <label>Sort Field <input id="sortField" placeholder="created_at"/></label>
  <label>Sort Direction <select id="sortDir"><option value="desc">Descending</option><option value="asc">Ascending</option></select></label>
  <label>Record Limit <input id="limit" placeholder="100"/></label>
  <div style="display:flex;gap:8px;margin-top:8px;align-items:center">
    <label style="flex:1"><input type="checkbox" id="canInsert"/> Can Insert</label>
    <label style="flex:1"><input type="checkbox" id="canUpdate"/> Can Update</label>
    <label style="flex:1"><input type="checkbox" id="canDelete"/> Can Delete</label>
  </div>
  <div style="margin-top:12px">
    <button id="createObj">Create Data Object</button>
  </div>

  <hr style="margin:18px 0" />
  <h3>Data Objects</h3>
  <div id="objectsList">No data objects created yet.</div>

  <h3 style="margin-top:12px">Data Preview</h3>
  <pre id="preview" style="background:#f3f4f6;padding:12px;border-radius:6px;min-height:120px">No data objects created yet.</pre>
  <script>
    const vscode = acquireVsCodeApi();
    document.getElementById('save').addEventListener('click', ()=>{
      const config = { url: document.getElementById('url').value.trim(), anonKey: document.getElementById('anon').value.trim(), projectName: document.getElementById('name').value.trim() };
      vscode.postMessage({ command: 'saveConfig', config });
    });
    document.getElementById('test').addEventListener('click', ()=>{
      vscode.postMessage({ command: 'testConnection' });
    });
    document.getElementById('load').addEventListener('click', ()=>{
      const table = document.getElementById('table').value.trim();
      document.getElementById('result').innerText = 'Loading...';
      vscode.postMessage({ command: 'loadTable', table });
    });
    document.getElementById('clear').addEventListener('click', ()=>{
      vscode.postMessage({ command: 'clearConfig' });
      document.getElementById('url').value = '';
      document.getElementById('anon').value = '';
      document.getElementById('name').value = '';
    });
    document.getElementById('createObj').addEventListener('click', ()=>{
      const id = document.getElementById('dataId').value.trim() || undefined;
      const viewName = document.getElementById('tableName').value.trim();
      const fieldsRaw = document.getElementById('fields').value.trim();
      const fields = fieldsRaw ? fieldsRaw.split(',').map(s=>s.trim()).filter(Boolean) : undefined;
      let where;
      try { where = document.getElementById('where').value.trim() ? JSON.parse(document.getElementById('where').value.trim()) : undefined; } catch(e){ return alert('Where must be valid JSON'); }
      const sortField = document.getElementById('sortField').value.trim() || undefined;
      const sortDir = document.getElementById('sortDir').value || undefined;
      const limit = parseInt(document.getElementById('limit').value) || undefined;
      const canInsert = !!document.getElementById('canInsert').checked;
      const canUpdate = !!document.getElementById('canUpdate').checked;
      const canDelete = !!document.getElementById('canDelete').checked;

      const opts = { viewName, fields, whereClauses: where ? Object.keys(where).map(k=>({ field: k, operator: 'equals', value: where[k] })) : undefined, sort: sortField ? { field: sortField, direction: sortDir } : undefined, recordLimit: limit, canInsert, canUpdate, canDelete };
      vscode.postMessage({ command: 'createDataObject', opts, viewName, id });
    });

    // request list of data objects stored in workspace state
    vscode.postMessage({ command: 'getDataObjects' });
    // request existing config
    vscode.postMessage({ command: 'getConfig' });
    window.addEventListener('message', event => {
      const msg = event.data;
      if (msg.command === 'config' && msg.config) {
        document.getElementById('url').value = msg.config.url || '';
        document.getElementById('anon').value = msg.config.anonKey || '';
        document.getElementById('name').value = msg.config.projectName || '';
      }
      if (msg.command === 'tableError') {
        document.getElementById('result').innerText = 'Error: ' + msg.error;
      }
      if (msg.command === 'tableLoaded') {
        const sample = JSON.stringify(msg.sample, null, 2);
        document.getElementById('result').innerText = 'Loaded table: ' + msg.table + '\nSample row(s):\n' + sample;
      }
      if (msg.command === 'dataObjectsList') {
        const list = msg.list || [];
        if (!list.length) {
          document.getElementById('objectsList').innerText = 'No data objects created yet.';
        } else {
          const html = list.map(l=>`<div style="padding:8px;border:1px solid #e5e7eb;border-radius:6px;margin-bottom:8px"><strong>${l.id}</strong> — ${l.viewName} <br/><small>Created: ${l.createdAt}</small> <div style="margin-top:6px"><button data-id="${l.id}" class="previewBtn">Preview</button></div></div>`).join('');
          document.getElementById('objectsList').innerHTML = html;
          Array.from(document.getElementsByClassName('previewBtn')).forEach(b => b.addEventListener('click', (ev) => {
            const id = ev.target.getAttribute('data-id');
            document.getElementById('preview').innerText = 'Loading preview...';
            vscode.postMessage({ command: 'previewData', id });
          }));
        }
      }
      if (msg.command === 'createError') {
        alert('Failed to create data object: ' + msg.error);
      }
      if (msg.command === 'previewData') {
        const p = document.getElementById('preview');
        if (msg.error) p.innerText = 'Error: ' + msg.error;
        else if (msg.warning) p.innerText = 'Warning: ' + msg.warning + '\n\n' + JSON.stringify(msg.data || [], null, 2);
        else p.innerText = JSON.stringify(msg.data || [], null, 2);
      }
    });
  </script>
</body>
</html>`;
}

module.exports = { activate, deactivate };
