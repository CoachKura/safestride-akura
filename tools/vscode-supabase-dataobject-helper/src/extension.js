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
  <script>
    const vscode = acquireVsCodeApi();
    document.getElementById('save').addEventListener('click', ()=>{
      const config = { url: document.getElementById('url').value.trim(), anonKey: document.getElementById('anon').value.trim(), projectName: document.getElementById('name').value.trim() };
      vscode.postMessage({ command: 'saveConfig', config });
    });
    document.getElementById('test').addEventListener('click', ()=>{
      vscode.postMessage({ command: 'testConnection' });
    });
    // request existing config
    vscode.postMessage({ command: 'getConfig' });
    window.addEventListener('message', event => {
      const msg = event.data;
      if (msg.command === 'config' && msg.config) {
        document.getElementById('url').value = msg.config.url || '';
        document.getElementById('anon').value = msg.config.anonKey || '';
        document.getElementById('name').value = msg.config.projectName || '';
      }
    });
  </script>
</body>
</html>`;
}

module.exports = { activate, deactivate };
