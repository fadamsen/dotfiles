function Clear-DockerUnusedItems {
  Write-Host 'Removing unused containers...'
  docker container prune

  Write-Host 'Deleting unused images...'
  docker image prune -a

  Write-Host 'Removing unused volumes...'
  docker volume prune

  Write-Host 'Clearing Docker build cache...'
  docker builder prune
}

function Compress-DockerDataDisk {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
  param()

  $vhdPath = "$($env:LOCALAPPDATA)\Docker\wsl\disk\docker_data.vhdx"

  if (-not (Test-Path -Path $vhdPath)) {
    Write-Error "Cannot find Docker Data Disk at $vhdPath."
    return
  }

  if ($PSCmdlet.ShouldProcess('Windows Subsystem for Linux', 'Shutdown')) {
    Write-Host 'Shutting down WSL...'
    wsl --shutdown

    if ($PSCmdlet.ShouldProcess('Docker Data Disk', 'Compact')) {
      $sizeBefore = (Get-Item $vhdPath).Length / 1GB

      Write-Host 'Compacting Docker Data Disk...'
      Optimize-VHD -Path $vhdPath

      $sizeAfter = (Get-Item $vhdPath).Length / 1GB
      $sizeReduction = $sizeBefore - $sizeAfter
      $percentageReduction = $sizeReduction / $sizeBefore

      $reduction = "Reduced Docker Data Disk size from {0:F1} GB to {1:F1} GB, a {2:F1} GB / {3:P2} reduction." -f $sizeBefore, $sizeAfter, $sizeReduction, $percentageReduction

      Write-Host $reduction
    }
  }
}

function ConvertFrom-RegexMatches {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Position = 0, ValueFromPipeline)]
    [System.Text.RegularExpressions.Match] $Match,

    [Parameter(Position = 1)]
    [string] $KeyName = 'key',

    [Parameter(Position = 2)]
    [string] $ValueName = 'value'
  )

  begin {
    $result = [ordered]@{}
  }

  process {
    $result[$Match.Groups[$KeyName].Value] = $Match.Groups[$ValueName].Value
  }

  end {
    [pscustomobject]$result
  }
}

function Edit-ChezmoiFile {
  param(
    [Parameter(Position = 0)]
    [string]$Query = '.'
  )

  $file = fd --hidden $Query $(chezmoi source-path) | fzf

  if ($file) {
    nvim $file
  }
}

function Get-GpgKey {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param()

  if (-not (Get-Command -Name gpg -ErrorAction SilentlyContinue)) {
    throw 'The gpg program is not installed.'
  }

  $records = gpg --list-keys --with-colons

  foreach ($record in $records) {
    $fields = $record -split ':'

    switch ($fields[0]) {
      'pub' {
        if ($key -ne $null) {
          [pscustomobject]$key
        }

        $key = @{
          Id = $fields[4].Substring($fields[4].Length - 8)
          KeyId = $fields[4]
          # https://github.com/gpg/gnupg/blob/master/doc/DETAILS#field-2---validity
          Validity = switch ($fields[1][0]) {
            '-' { 'Undefined' }
            'd' { 'Disabled' }
            'e' { 'Expired' }
            'f' { 'FullyValid' }
            'i' { 'Invalid' }
            'm' { 'MarginalValid' }
            'n' { 'NotValid' }
            'o' { 'Unknown '}
            'q' { 'Undefined' }
            'r' { 'Revoked' }
            's' { 'HasSpecialValidity' }
            'u' { 'UltimatelyValid' }
            'w' { 'HasWellKnownPrivatePart' }
          }
          # https://github.com/gpg/gnupg/blob/master/doc/DETAILS#field-12---key-capabilities
          KeyCapabilities = foreach ($keyCapability in ($fields[11] -split '')) {
            switch ($keyCapability) {
              '?' { 'Unknown'}
              'A' { 'Authentication' }
              'C' { 'Certify' }
              'D' { 'Disabled' }
              'E' { 'Encrypt' }
              'G' { 'GroupKey' }
              'R' { 'RestrictedEncryption' }
              'S' { 'Sign' }
              'T' { 'Timestamping' }
            }
          }
          KeyLength = $fields[2]
          # https://www.rfc-editor.org/rfc/rfc9580.html#name-public-key-algorithms
          PublicKeyAlgorithm = switch ($fields[3]) {
            1 { 'RSA (Encrypt or Sign)' }
            2 { 'RSA Encrypt-Only' }
            3 { 'RSA Sign-Only' }
            16 { 'Elgamal (Encrypt-Only)' }
            17 { 'DSA (Digital Signature Algorithm)' }
            18 { 'ECDH public key algorithm' }
            19 { 'ECDSA public key algorithm' }
            20 { 'Reserved (formerly Elgamal Encrypt or Sign)' }
            21 { 'Reserved for Diffie-Hellman (X9.42, as defined for IETF-S/MIME)' }
            22 { 'EdDSALegacy (deprecated)' }
            23 { 'Reserved (AEDH)' }
            24 { 'Reserved (AEDSA)' }
            25 { 'X25519' }
            26 { 'X448' }
            27 { 'Ed25519' }
            28 { 'Ed448' }
          }
          EccCurveName = $fields[16]
          CreationDate = [System.DateTimeOffset]::FromUnixTimeSeconds($fields[5])
          ExpirationDate = [System.DateTimeOffset]::FromUnixTimeSeconds($fields[6])
        }
      }
      'uid' {
        $key['UserId'] = $fields[9]
        $key['UserIdHash'] = $fields[7]
        $key['CreationDate'] = [System.DateTimeOffset]::FromUnixTimeSeconds($fields[5])
        $key['Subkeys'] = @()
      }
      'sub' {
        $key['Subkeys'] += [pscustomobject]@{
          Id = $fields[4].Substring($fields[4].Length - 8)
          KeyId = $fields[4]
          # https://github.com/gpg/gnupg/blob/master/doc/DETAILS#field-2---validity
          Validity = switch ($fields[1][0]) {
            '-' { 'Undefined' }
            'd' { 'Disabled' }
            'e' { 'Expired' }
            'f' { 'FullyValid' }
            'i' { 'Invalid' }
            'm' { 'MarginalValid' }
            'n' { 'NotValid' }
            'o' { 'Unknown '}
            'q' { 'Undefined' }
            'r' { 'Revoked' }
            's' { 'HasSpecialValidity' }
            'u' { 'UltimatelyValid' }
            'w' { 'HasWellKnownPrivatePart' }
          }
          # https://github.com/gpg/gnupg/blob/master/doc/DETAILS#field-12---key-capabilities
          KeyCapabilities = foreach ($keyCapability in ($fields[11] -split '')) {
            switch ($keyCapability) {
              '?' { 'Unknown'}
              'a' { 'Authentication' }
              'c' { 'Certify' }
              'e' { 'Encrypt' }
              'g' { 'GroupKey' }
              'r' { 'RestrictedEncryption' }
              's' { 'Sign' }
              't' { 'Timestamping' }
            }
          }
          KeyLength = $fields[2]
          # https://www.rfc-editor.org/rfc/rfc9580.html#name-public-key-algorithms
          PublicKeyAlgorithm = switch ($fields[3]) {
            1 { 'RSA (Encrypt or Sign)' }
            2 { 'RSA Encrypt-Only' }
            3 { 'RSA Sign-Only' }
            16 { 'Elgamal (Encrypt-Only)' }
            17 { 'DSA (Digital Signature Algorithm)' }
            18 { 'ECDH public key algorithm' }
            19 { 'ECDSA public key algorithm' }
            20 { 'Reserved (formerly Elgamal Encrypt or Sign)' }
            21 { 'Reserved for Diffie-Hellman (X9.42, as defined for IETF-S/MIME)' }
            22 { 'EdDSALegacy (deprecated)' }
            23 { 'Reserved (AEDH)' }
            24 { 'Reserved (AEDSA)' }
            25 { 'X25519' }
            26 { 'X448' }
            27 { 'Ed25519' }
            28 { 'Ed448' }
          }
          EccCurveName = $fields[16]
          CreationDate = [System.DateTimeOffset]::FromUnixTimeSeconds($fields[5])
          ExpirationDate = [System.DateTimeOffset]::FromUnixTimeSeconds($fields[6])
        }
      }
    }
  }

  if ($key -ne $null) {
    [pscustomobject]$key
  }
}

function Export-GpgKey {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Mandatory)]
    [string] $UserId
  )

  $keyId = Get-GpgKey |
    Where-Object UserId -like "*$UserId*" |
    Select-Object -ExpandProperty Subkeys |
    Where-Object KeyCapabilities -contains Sign |
    Select-Object -ExpandProperty KeyId

  (gpg --armor --export "$keyId!") -join "`n"
}

function New-ReportGeneratorReport {
  [CmdletBinding()]
  param(
    [Parameter()]
    [string[]] $Report = '**/TestResults/**/coverage.cobertura.*.xml',

    [Parameter()]
    [string] $TargetDirectory = 'coveragereport',

    [Parameter()]
    [ValidateSet(
      'Badges', 'Clover', 'Cobertura', 'CodeClimate', 'CsvSummary', 'Html',
      'HtmlChart', 'HtmlInline', 'HtmlInline_AzurePipelines',
      'HtmlInline_AzurePipelines_Dark', 'HtmlInline_AzurePipelines_Light',
      'HtmlSummary', 'Html_BlueRed', 'Html_BlueRed_Summary', 'Html_Dark',
      'Html_Light', 'JsonSummary', 'Latex', 'LatexSummary', 'MHtml', 'Markdown',
      'MarkdownAssembliesSummary', 'MarkdownDeltaSummary', 'MarkdownSummary',
      'MarkdownSummaryGithub', 'OpenCover', 'SonarQube', 'SvgChart',
      'TeamCitySummary', 'TextDeltaSummary', 'TextSummary', 'Xml', 'XmlSummary',
      'cjson', 'lcov'
    )]
    [string[]] $ReportType = 'Html',

    [Parameter()]
    [string] $ExecutablePath = 'reportgenerator.exe'
  )

  process {
    $arguments = @(
      "-reports:$($Report -join ';')"
      "-reporttypes:$($ReportType -join ';')"
      "-targetdir:$TargetDirectory"
    )

    Write-Verbose "Executing: $ExecutablePath $arguments"

    try {
      $env:DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = '1'
      $env:REPORTGENERATOR_LICENSE = Get-Secret -Name reportgenerator-license -AsPlainText
      & $ExecutablePath @arguments

      if ($LASTEXITCODE -ne 0) {
        throw "ReportGenerator exited with code $LASTEXITCODE."
      }
    } finally {
      Remove-Item env:DOTNET_SYSTEM_GLOBALIZATION_INVARIANT
      Remove-Item env:REPORTGENERATOR_LICENSE
    }
  }
}

function Publish-JujutsuBookmark {
  [CmdletBinding()]
  param(
      [Parameter(Mandatory)]
      [string] $Bookmark,

      [Parameter(Mandatory)]
      [string] $Revision
  )

  jj bookmark advance $Bookmark --to $Revision

  if ($LASTEXITCODE -ne 0) {
      throw "Failed to update Jujutsu bookmark '$Bookmark'."
  }

  jj git push --bookmark $Bookmark

  if ($LASTEXITCODE -ne 0) {
      throw "Failed to push Jujutsu bookmark '$Bookmark'."
  }
}

function Read-YesNo {
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Message,

    [bool]$DefaultYes = $false
  )

  $choices = [System.Management.Automation.Host.ChoiceDescription[]]@(
    ([System.Management.Automation.Host.ChoiceDescription]::new('&Yes', 'Yes')),
    ([System.Management.Automation.Host.ChoiceDescription]::new('&No',  'No'))
  )

  $default = if ($DefaultYes) { 0 } else { 1 }
  $selection = $Host.UI.PromptForChoice('Confirm', $Message, $choices, $default)

  return $selection -eq 0
}

function Run-Command {
  param (
    [Parameter(Mandatory, Position = 0)]
    [string]$Command
  )

  [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert($Command)
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

function Save-Chezmoi {
  [CmdletBinding()]
  param()

  $dir = chezmoi source-path

  jj --repository $dir status

  if (Read-YesNo 'Save changes?') {
    jj --repository $dir new
    Publish-JujutsuBookmark -Bookmark main -Revision '@-'
  }
}

#region Git functions

function Find-GitRepository {
  [CmdletBinding()]
  [OutputType([System.IO.DirectoryInfo])]
  param(
    [Parameter(Position = 0)]
    [string] $Path = '.'
  )

  Get-ChildItem -Path $Path -Force -Recurse -Depth 2 -Directory |
    Where-Object Name -eq .git |
    ForEach-Object { Get-Item $_.Parent }
}

function Get-GitBranch {
  [CmdletBinding()]
  [OutputType([string])]
  param(
    [Parameter(Position = 0)]
    [string] $Path
  )

  $gitParameters = @()

  if ($PSBoundParameters.ContainsKey('Path')) {
    $gitParameters += @('-C', $Path)
  }

  git @gitParameters branch --show-current
}

function Get-GitRepository {
  [CmdletBinding()]
  [OutputType([pscustomobject])]
  param(
    [Parameter(Position = 0)]
    [string] $Path = '.'
  )

  return [pscustomobject]@{
    Name = (Get-Item $Path).Name
    Branch = Get-GitBranch -Path $Path
    Clean = Test-GitRepositoryStatus -Path $Path
  }
}

function Test-GitRepository {
  [CmdletBinding()]
  [OutputType([bool])]
  param(
    [Parameter(Position = 0)]
    [string] $Path
  )

  $gitParameters = @()

  if ($PSBoundParameters.ContainsKey('Path')) {
    $gitParameters += @('-C', $Path)
  }

  git @gitParameters rev-parse --is-inside-work-tree 1>$null 2>$null

  $?
}

function Test-GitRepositoryStatus {
  [CmdletBinding()]
  [OutputType([bool])]
  param(
    [Parameter(Position = 0)]
    [string] $Path
  )

  $gitParameters = @()

  if ($PSBoundParameters.ContainsKey('Path')) {
    $gitParameters += @('-C', $Path)
  }

  $status = @(git @gitParameters status --porcelain=v1) 2>$null

  $status.Count -eq 0
}

#endregion
