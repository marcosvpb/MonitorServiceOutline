# Marcos Services Dashboard
# Execute with: powershell -ExecutionPolicy Bypass -File .\ServicesDashboard.ps1
# Opens a local dashboard at http://localhost:8765

$ErrorActionPreference = "Stop"
$prefix = "http://localhost:8765/"

$html = @'
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Marcos - Windows Services</title>
<style>
:root{color-scheme:dark;--bg:#0d1117;--panel:#161b22;--border:#30363d;--text:#e6edf3;--muted:#8b949e;--green:#3fb950;--red:#f85149;--gray:#8b949e;--cyan:#39c5cf}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--text);font:14px Segoe UI,Arial,sans-serif}
main{max-width:1100px;margin:40px auto;padding:0 22px}
header{display:flex;justify-content:space-between;align-items:center;gap:16px;margin-bottom:24px;flex-wrap:wrap}
h1{font-size:25px;margin:0 0 6px}p{color:var(--muted);margin:0}
button{background:#238636;color:white;border:1px solid #2ea043;border-radius:7px;padding:10px 15px;cursor:pointer;font-weight:600}
button:hover{background:#2ea043}button:disabled{opacity:.6;cursor:wait}
.stats{display:flex;gap:10px;flex-wrap:wrap;margin:20px 0}
.stat{background:var(--panel);border:1px solid var(--border);border-radius:9px;padding:12px 16px;min-width:130px}
.stat strong{display:block;font-size:22px;margin-top:4px}.stat span{color:var(--muted);font-size:12px}
.panel{background:var(--panel);border:1px solid var(--border);border-radius:10px;overflow:hidden}
.toolbar{padding:14px;border-bottom:1px solid var(--border);display:flex;gap:12px;align-items:center;justify-content:space-between;flex-wrap:wrap}
input{background:#0d1117;color:var(--text);border:1px solid var(--border);border-radius:6px;padding:9px 11px;min-width:220px}
table{width:100%;border-collapse:collapse}th,td{text-align:left;padding:13px 16px;border-bottom:1px solid var(--border)}
th{font-size:11px;text-transform:uppercase;letter-spacing:.06em;color:var(--muted);background:#11161d}
tr:last-child td{border-bottom:0}tbody tr:hover{background:#1c222b}
.name{font-weight:600}.sub{display:block;color:var(--muted);font-size:12px;margin-top:4px}
.badge{display:inline-flex;align-items:center;gap:7px;padding:5px 9px;border-radius:20px;font-size:12px;font-weight:700;white-space:nowrap}
.dot{width:8px;height:8px;border-radius:50%;background:currentColor}
.running{color:var(--green);background:#17351f}.running .dot{animation:pulse 1s infinite}
.stopped{color:var(--red);background:#3a1d20}.disabled{color:#b1bac4;background:#30363d}.manual{color:var(--cyan);background:#12343a}
@keyframes pulse{0%,100%{opacity:1;box-shadow:0 0 0 0 currentColor}50%{opacity:.25;box-shadow:0 0 0 5px transparent}}
.empty{padding:35px;text-align:center;color:var(--muted)}
.footer{color:var(--muted);font-size:12px;margin:12px 2px}
@media(max-width:650px){main{margin:22px auto;padding:0 12px}th,td{padding:11px 9px}.hide-mobile{display:none}input{min-width:0;width:100%}}
</style>
</head>
<body>
<main>
<header>
 <div><h1>Marcos - Windows Services</h1><p>Monitoramento dos serviços com nome iniciado por “Marcos - ”</p></div>
 <button id="refresh">↻ Atualizar agora</button>
</header>
<section class="stats">
 <div class="stat"><span>Total encontrados</span><strong id="total">—</strong></div>
 <div class="stat"><span>Em execução</span><strong id="runningCount" style="color:var(--green)">—</strong></div>
 <div class="stat"><span>Parados</span><strong id="stoppedCount" style="color:var(--red)">—</strong></div>
 <div class="stat"><span>Desabilitados</span><strong id="disabledCount">—</strong></div>
</section>
<section class="panel">
 <div class="toolbar"><strong>Serviços monitorados</strong><input id="filter" placeholder="Filtrar serviços..."></div>
 <div style="overflow-x:auto"><table>
 <thead><tr><th>Serviço</th><th>Status</th><th>Inicialização</th><th class="hide-mobile">Nome interno</th></tr></thead>
 <tbody id="services"><tr><td colspan="4" class="empty">Carregando serviços...</td></tr></tbody>
 </table></div>
</section>
<div class="footer" id="updated">A atualização automática ocorre a cada 5 segundos.</div>
</main>
<script>
let allServices=[];
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function stateBadge(s){
 const running=String(s.State).toLowerCase()==='running';
 return `<span class="badge ${running?'running':'stopped'}"><i class="dot"></i>${running?'Running':'Stopped'}</span>`;
}
function startupBadge(s){
 const m=String(s.StartMode).toLowerCase();
 if(m==='disabled')return '<span class="badge disabled">Disabled</span>';
 if(m==='manual')return '<span class="badge manual">Manual</span>';
 return `<span class="badge">${esc(s.StartMode)}</span>`;
}
function render(){
 const q=document.getElementById('filter').value.toLowerCase();
 const list=allServices.filter(s=>(s.DisplayName+' '+s.Name).toLowerCase().includes(q));
 document.getElementById('total').textContent=allServices.length;
 document.getElementById('runningCount').textContent=allServices.filter(s=>s.State.toLowerCase()==='running').length;
 document.getElementById('stoppedCount').textContent=allServices.filter(s=>s.State.toLowerCase()==='stopped').length;
 document.getElementById('disabledCount').textContent=allServices.filter(s=>s.StartMode.toLowerCase()==='disabled').length;
 const body=document.getElementById('services');
 body.innerHTML=list.length?list.map(s=>`<tr>
 <td><span class="name">${esc(s.DisplayName)}</span><span class="sub">${esc(s.Description||'')}</span></td>
 <td>${stateBadge(s)}</td><td>${startupBadge(s)}</td><td class="hide-mobile"><code>${esc(s.Name)}</code></td>
 </tr>`).join(''):'<tr><td colspan="4" class="empty">Nenhum serviço encontrado.</td></tr>';
}
async function refresh(){
 const b=document.getElementById('refresh');b.disabled=true;
 try{
  const r=await fetch('/api/services',{cache:'no-store'});
  if(!r.ok)throw new Error('HTTP '+r.status);
  allServices=await r.json();render();
  document.getElementById('updated').textContent='Última atualização: '+new Date().toLocaleTimeString()+' · atualização automática a cada 5 segundos.';
 }catch(e){document.getElementById('updated').textContent='Erro ao consultar serviços: '+e.message;}
 finally{b.disabled=false;}
}
document.getElementById('refresh').addEventListener('click',refresh);
document.getElementById('filter').addEventListener('input',render);
refresh();setInterval(refresh,5000);
</script>
</body></html>
'@

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
    Write-Host ""
    Write-Host "Painel iniciado: $prefix" -ForegroundColor Green
    Write-Host "Mantenha esta janela aberta. Pressione Ctrl+C para encerrar." -ForegroundColor Yellow
    Start-Process $prefix

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            $request = $context.Request
            $response = $context.Response
            $response.Headers.Add("Cache-Control", "no-store")

            if ($request.Url.AbsolutePath -eq "/api/services") {
                $services = Get-CimInstance -ClassName Win32_Service |
                    Where-Object { $_.DisplayName -like "Marcos - *" } |
                    Sort-Object DisplayName |
                    Select-Object @{
                        Name="Name";Expression={$_.Name}
                    }, @{
                        Name="DisplayName";Expression={$_.DisplayName}
                    }, @{
                        Name="State";Expression={$_.State}
                    }, @{
                        Name="StartMode";Expression={$_.StartMode}
                    }, @{
                        Name="Description";Expression={$_.Description}
                    }

                $content = ConvertTo-Json -InputObject @($services) -Depth 4 -Compress
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
                $response.ContentType = "application/json; charset=utf-8"
            } else {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
                $response.ContentType = "text/html; charset=utf-8"
            }

            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.OutputStream.Close()
        } catch {
            try { $context.Response.StatusCode = 500; $context.Response.Close() } catch {}
            Write-Warning $_
        }
    }
}
finally {
    if ($listener.IsListening) { $listener.Stop() }
    $listener.Close()
}
