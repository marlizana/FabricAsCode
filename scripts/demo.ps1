<#
  Guion de la demo «Y yo aqui creando workspaces a mano: Terraform al rescate».
  Compatible con Windows PowerShell 5.1 y PowerShell 7. Ejecutar desde la raiz del repo:

    .\scripts\demo.ps1 <accion>

  Antes de la charla
    env          Carga IDs y lee el secret del SP y el PAT desde el portapapeles.
                 IMPORTANTE, con punto delante:   . .\scripts\demo.ps1 env
    init         terraform init + workspace de estado "netcoreconf"
    estado       Estado de la capacity (Active / Paused)

  En directo
    hola         Ejemplo «cabe en un fichero .tf» (plan del ejemplo 01)
    proyecto     Pregunta el nombre del proyecto (ventas, stocks...)
    plan         terraform plan
    apply        terraform apply
    qa           Anade el entorno "qa" (environments/netcoreconf-qa.tfvars) y hace plan;
                 a partir de ahi plan/apply/drift lo incluyen. "sin-qa" lo quita.
    drift        plan tras tocar algo a mano en el portal
    reanuda      Reanuda la capacity
    pausa        Pausa la capacity ("y asi se deja de pagar")

  Preparar y limpiar
    prepara      Crea solo la capacity y el budget (antes de la charla; luego el plan da 81)
    limpia       Borra workspaces, grupos y roles; deja capacity y budget (entre ensayos)
    destroy      Borra todo lo de esta sesion (capacity incluida)
#>
param([Parameter(Position = 0)][string]$Accion = "help")

$ErrorActionPreference = "Stop"
$Root    = Split-Path -Parent $PSScriptRoot
$VarFile = "environments/netcoreconf.tfvars"
$TfWs    = "netcoreconf"
$ProjectFile = Join-Path $Root ".demo-project"
$QaFlag      = Join-Path $Root ".demo-qa"
$QaVarFile   = "environments/netcoreconf-qa.tfvars"

function VarArgs {
  $a = @("-var-file=$VarFile")
  if (Test-Path $QaFlag) { $a += "-var-file=$QaVarFile" }  # el ultimo var-file gana
  ,$a
}

$TenantId       = "bc6b1bb6-0e6c-4cc2-a2f4-b3603c4dd6a8"
$SubscriptionId = "c52466ac-5cb2-4bd7-87e3-770ee8c4c12f"
$ClientId       = "36341d06-ef04-4823-8fe8-075ee14b0908"

function Say($msg, $color = "Cyan") { Write-Host "`n>> $msg" -ForegroundColor $color }

function Tf {
  param([string[]]$TfArgs)
  # Argumentos como array: PowerShell no parte "-target=module.x" por el punto.
  Push-Location $Root
  try { & terraform @TfArgs; if ($LASTEXITCODE -ne 0) { throw "terraform $($TfArgs[0]) fallo" } }
  finally { Pop-Location }
}

function Require-Env {
  if (-not $env:ARM_CLIENT_SECRET -or $env:ARM_CLIENT_SECRET.Length -lt 20) {
    throw "Falta el secret del SP. Ejecuta antes: .\scripts\demo.ps1 env"
  }
}

function Load-Project {
  if (-not $env:TF_VAR_project_name -and (Test-Path $ProjectFile)) {
    $env:TF_VAR_project_name = (Get-Content $ProjectFile -Raw).Trim()
  }
  if (-not $env:TF_VAR_project_name) { Ask-Project }
  Say "Proyecto: $($env:TF_VAR_project_name)" "Yellow"
}

function Ask-Project {
  do {
    $p = (Read-Host "¿Como se llama el proyecto? (ventas, stocks...)").Trim().ToLower()
    $ok = $p -match '^[a-z][a-z0-9-]{1,30}$'
    if (-not $ok) { Write-Host "Minusculas, digitos y guiones; empieza por letra." -ForegroundColor Red }
  } until ($ok)
  $env:TF_VAR_project_name = $p
  Set-Content -Path $ProjectFile -Value $p -NoNewline
}

function Arm-Token {
  $body = @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $env:ARM_CLIENT_SECRET
    scope         = "https://management.azure.com/.default"
  }
  (Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $body).access_token
}

function Capacity-Uri {
  Push-Location $Root
  try { $id = (& terraform output -raw capacity_arm_id) } finally { Pop-Location }
  if (-not $id) { throw "No hay capacity en el estado de '$TfWs'. ¿Has hecho apply?" }
  "https://management.azure.com$id"
}

function Capacity-Call($verb) {
  Require-Env
  $h = @{ Authorization = "Bearer $(Arm-Token)" }
  $uri = Capacity-Uri
  $c = Invoke-RestMethod -Headers $h -Uri "${uri}?api-version=2023-11-01"
  $state = $c.properties.state
  if ($verb -eq "get") { Say "$($c.name): $state ($($c.sku.name))" "Green"; return }

  $target = @{ resume = "Active"; suspend = "Paused" }[$verb]
  if ($state -eq $target) { Say "$($c.name) ya esta $state. Nada que hacer." "Green"; return }
  if ($state -notin @("Active", "Paused")) {
    Say "$($c.name) esta en '$state' (cambiando de estado). Espera un minuto y prueba: .\scripts\demo.ps1 estado" "Yellow"
    return
  }
  try {
    Invoke-RestMethod -Method Post -Headers $h -Uri "${uri}/${verb}?api-version=2023-11-01" | Out-Null
    Say "$($c.name): $verb solicitado (estaba $state). Tarda unos segundos; comprueba con: .\scripts\demo.ps1 estado" "Green"
  } catch {
    Say "Azure no acepta '$verb' ahora mismo (suele ser porque ya esta cambiando de estado). Espera un minuto y repite." "Yellow"
    Write-Host $_.ErrorDetails.Message -ForegroundColor DarkGray
  }
}

switch ($Accion) {
  "env" {
    $env:ARM_TENANT_ID = $TenantId; $env:ARM_SUBSCRIPTION_ID = $SubscriptionId; $env:ARM_CLIENT_ID = $ClientId
    $env:FABRIC_TENANT_ID = $TenantId; $env:FABRIC_CLIENT_ID = $ClientId
    Read-Host "Copia el SECRET del service principal y pulsa Enter" | Out-Null
    $env:ARM_CLIENT_SECRET = (Get-Clipboard).Trim(); $env:FABRIC_CLIENT_SECRET = $env:ARM_CLIENT_SECRET
    # Fabric CLI (fab) con el mismo service principal, sin "fab auth login"
    $env:FAB_SPN_CLIENT_ID = $ClientId; $env:FAB_SPN_CLIENT_SECRET = $env:ARM_CLIENT_SECRET; $env:FAB_TENANT_ID = $TenantId
    # Fabric CLI (fab) con el mismo service principal, sin "fab auth login"
    $env:FAB_SPN_CLIENT_ID = $ClientId; $env:FAB_SPN_CLIENT_SECRET = $env:ARM_CLIENT_SECRET; $env:FAB_TENANT_ID = $TenantId
    Read-Host "Copia el PAT de GitHub y pulsa Enter" | Out-Null
    $env:GITHUB_TOKEN = (Get-Clipboard).Trim()
    Set-Clipboard -Value "---"
    Say "Secret: $($env:ARM_CLIENT_SECRET.Length) caracteres · PAT: $($env:GITHUB_TOKEN.Length) caracteres (esperado ~40 y 40)" "Green"
    Write-Host "Ojo: hay que ejecutarlo con punto delante para que las variables se queden en tu sesion:  . .\scripts\demo.ps1 env" -ForegroundColor Yellow
  }
  "init" {
    Tf @("init")
    Tf @("workspace", "select", "-or-create", $TfWs)
    Say "Estado de Terraform: workspace '$TfWs'" "Green"
  }
  "hola" {
    Require-Env
    Push-Location (Join-Path $Root "examples/01-hola-workspace")
    try {
      Get-Content main.tf | Select-String -NotMatch '^\s*#' | Where-Object { $_.Line.Trim() } | ForEach-Object { $_.Line }
      & terraform init -input=false | Out-Null
      Push-Location $Root; try { $cap = (& terraform output -raw capacity_id) } finally { Pop-Location }
      & terraform plan "-var=capacity_id=$cap"
    } finally { Pop-Location }
  }
  "proyecto" { Ask-Project; Say "Proyecto: $($env:TF_VAR_project_name)" "Yellow" }
  "plan"     { Require-Env; Load-Project; Tf (@("plan") + (VarArgs)) }
  "apply"    { Require-Env; Load-Project; Tf (@("apply") + (VarArgs) + @("-parallelism=8")) }
  "qa" {
    Require-Env; Load-Project
    Set-Content -Path $QaFlag -Value "qa"
    Say "El cambio es una linea:" "Yellow"
    Get-Content (Join-Path $Root $QaVarFile) | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() }
    Tf (@("plan") + (VarArgs))
    Write-Host "Si te gusta: .\scripts\demo.ps1 apply" -ForegroundColor DarkGray
  }
  "sin-qa"   { Remove-Item $QaFlag -ErrorAction SilentlyContinue; Say "QA fuera: el siguiente apply borra sus workspaces." "Yellow" }
  "drift"    { Require-Env; Load-Project; Say "¿Que ha cambiado alguien a mano?"; Tf (@("plan") + (VarArgs)) }
  "estado"   { Capacity-Call "get" }
  "reanuda"  { Capacity-Call "resume" }
  "pausa"    { Capacity-Call "suspend" }
  "prepara"  { Require-Env; Load-Project; Tf (@("apply") + (VarArgs) + @("-target=module.capacity", "-target=azurerm_consumption_budget_subscription.this")) }
  "limpia"   { Require-Env; Load-Project; Tf (@("destroy") + (VarArgs) + @("-target=module.medallion_cicd")); Remove-Item $QaFlag -ErrorAction SilentlyContinue }
  "destroy"  { Require-Env; Load-Project; Tf (@("destroy") + (VarArgs)); Remove-Item $QaFlag -ErrorAction SilentlyContinue }
  default    { $h = Get-Content $PSCommandPath; $end = [array]::IndexOf($h, "#>"); $h[1..($end - 1)] }
}
