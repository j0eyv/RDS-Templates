<#Author       : Akash Chawla
 #Revision     : Joey Verlinden
# Usage        : Remove Appx Packages
#>

#######################################
#   Remove Appx Packages        #######
#######################################


[CmdletBinding()]
  Param (
        [Parameter(
            Mandatory
        )]
        [System.String[]] $AppxPackages
 )

# Set global preference so non-terminating errors don't cause process failure
$ErrorActionPreference = 'SilentlyContinue'

 function Remove-ProvidedAppxPackages($AppxPackages) {
   
        Begin {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $templateFilePathFolder = "C:\AVDImage"
            Write-host "Starting AVD AIB Customization: Remove Appx Packages : $((Get-Date).ToUniversalTime()) "
        }

        Process {
            Foreach ($App in $AppxPackages) {
                try {
                    Write-Host "AVD AIB CUSTOMIZER PHASE : Processing package pattern: $($App)"

                    # Provisioned packages (image)
                    $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like ("*{0}*" -f $App) }
                    if ($prov) {
                        foreach ($p in $prov) {
                            try {
                                Write-Host "AVD AIB CUSTOMIZER PHASE : Removing Provisioned Package $($p.PackageName)"
                                Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction SilentlyContinue | Out-Null
                            } catch {
                                Write-Host "AVD AIB CUSTOMIZER PHASE : Failed to remove provisioned package $($p.PackageName) - $($_.Exception.Message)"
                            }
                        }
                    } else {
                        Write-Host "AVD AIB CUSTOMIZER PHASE : No provisioned package found for pattern '$App'"
                    }

                    # All users
                    $allUsersPkgs = Get-AppxPackage -AllUsers -Name ("*{0}*" -f $App) -ErrorAction SilentlyContinue
                    if ($allUsersPkgs) {
                        foreach ($pkg in $allUsersPkgs) {
                            try {
                                Write-Host "AVD AIB CUSTOMIZER PHASE : Attempting to remove [All Users] $($pkg.PackageFullName)"
                                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue | Out-Null
                            } catch {
                                Write-Host "AVD AIB CUSTOMIZER PHASE : Failed to remove AllUsers package $($pkg.PackageFullName) - $($_.Exception.Message)"
                            }
                        }
                    } else {
                        Write-Host "AVD AIB CUSTOMIZER PHASE : No AllUsers packages found for pattern '$App'"
                    }

                    # Current user
                    $curPkgs = Get-AppxPackage -Name ("*{0}*" -f $App) -ErrorAction SilentlyContinue
                    if ($curPkgs) {
                        foreach ($pkg in $curPkgs) {
                            try {
                                Write-Host "AVD AIB CUSTOMIZER PHASE : Attempting to remove $($pkg.PackageFullName)"
                                Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction SilentlyContinue | Out-Null
                            } catch {
                                Write-Host "AVD AIB CUSTOMIZER PHASE : Failed to remove package $($pkg.PackageFullName) - $($_.Exception.Message)"
                            }
                        }
                    } else {
                        Write-Host "AVD AIB CUSTOMIZER PHASE : No current user packages found for pattern '$App'"
                    }

                    # Special-case: MSPaint capability
                    if($App -eq "Microsoft.MSPaint") {
                        $PaintWindowsName = "Microsoft.Windows.MSPaint"
                        $pcaps = Get-WindowsCapability -Online -Name ("*{0}*" -f $PaintWindowsName) -ErrorAction SilentlyContinue
                        if ($pcaps) {
                            foreach ($cap in $pcaps) {
                                try {
                                    Write-Host "AVD AIB CUSTOMIZER PHASE : Removing Windows capability $($cap.Name)"
                                    Remove-WindowsCapability -Online -Name $cap.Name -ErrorAction SilentlyContinue | Out-Null
                                } catch {
                                    Write-Host "AVD AIB CUSTOMIZER PHASE : Failed to remove Windows capability $($cap.Name) - $($_.Exception.Message)"
                                }
                            }
                        } else {
                            Write-Host "AVD AIB CUSTOMIZER PHASE : No Windows capability matching $PaintWindowsName found."
                        }
                    }
                }
                catch {
                    Write-Host "AVD AIB CUSTOMIZER PHASE : Failed to process package pattern $App - $($_.Exception.Message)"
                    # Do not rethrow; continue with next package
                }
            } 
        }
        
        End {

            #Cleanup
            if ((Test-Path -Path $templateFilePathFolder -ErrorAction SilentlyContinue)) {
                Remove-Item -Path $templateFilePathFolder -Force -Recurse -ErrorAction Continue
            }
    
            $stopwatch.Stop()
            $elapsedTime = $stopwatch.Elapsed
            Write-Host "*** AVD AIB CUSTOMIZER PHASE : Remove Appx Packages -  Exit Code: $LASTEXITCODE ***"    
            Write-Host "Ending AVD AIB Customization : Remove Appx Packages - Time taken: $elapsedTime"

            # Ensure the script exits successfully so Azure Image Builder doesn't fail for non-critical removals
            Write-Host "AVD AIB CUSTOMIZER PHASE : Forcing exit 0 to avoid build failure from non-critical errors."
            exit 0
        }
 }

 Remove-ProvidedAppxPackages -AppxPackages $AppxPackages
