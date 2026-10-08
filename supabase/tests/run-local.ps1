# Uji migration Supabase di PostgreSQL lokal, tanpa akun Supabase.
# Memakai database sementara djournal_sb_test yang dihapus di akhir.
# Kredensial diambil dari user-secrets server .NET (tidak ditampilkan).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

$json = dotnet user-secrets list --json --project "$root\server\src\DJournal.Api" |
    Where-Object { $_ -notmatch '^//' } | Out-String | ConvertFrom-Json
$cs = @{}
foreach ($part in $json.'ConnectionStrings:Default'.Split(';')) {
    $kv = $part.Split('=', 2)
    if ($kv.Count -eq 2) { $cs[$kv[0].Trim().ToLower()] = $kv[1] }
}
$env:PGPASSWORD = $cs['password']
$port = if ($cs['port']) { $cs['port'] } else { '5432' }
$pgArgs = @('-h', $cs['host'], '-p', $port, '-U', $cs['username'], '-v', 'ON_ERROR_STOP=1', '-q')
$db = 'djournal_sb_test'

function Invoke-Psql([string[]]$extra) {
    psql @pgArgs @extra
    if ($LASTEXITCODE -ne 0) { throw "psql gagal (exit $LASTEXITCODE)" }
}

# Role anon/authenticated hanya ada di Supabase: buang baris grant/revoke.
$migration = Get-ChildItem "$root\supabase\migrations\*.sql" | Sort-Object Name | ForEach-Object {
    (Get-Content $_.FullName) | Where-Object { $_ -notmatch '^\s*(grant|revoke) execute' }
}
$tmp = New-TemporaryFile
$migration | Set-Content -Encoding utf8 $tmp

try {
    Invoke-Psql @('-d', 'postgres', '-c', "DROP DATABASE IF EXISTS $db") | Out-Null
    Invoke-Psql @('-d', 'postgres', '-c', "CREATE DATABASE $db") | Out-Null
    Invoke-Psql @('-d', $db, '-f', "$root\supabase\tests\local_harness.sql")
    Invoke-Psql @('-d', $db, '-f', $tmp.FullName)
    Invoke-Psql @('-d', $db, '-f', "$root\supabase\tests\sync_test.sql")
}
finally {
    psql @pgArgs -d postgres -c "DROP DATABASE IF EXISTS $db" | Out-Null
    Remove-Item $tmp
    Remove-Item Env:PGPASSWORD
}
