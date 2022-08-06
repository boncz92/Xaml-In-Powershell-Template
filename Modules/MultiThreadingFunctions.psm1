Function Set-Binding {
    Param($Target,$Property,$Index,$Name,$UpdateSourceTrigger)
 
    $Binding = New-Object System.Windows.Data.Binding
    $Binding.Path = "["+$Index+"]"
    $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
    if($UpdateSourceTrigger -ne $null){$Binding.UpdateSourceTrigger = $UpdateSourceTrigger}


    [void]$Target.SetBinding($Property,$Binding)
}

function FillDataContext($props){
    For ($i=0; $i -lt $props.Length; $i++) {
    $prop = $props[$i]
    $DataContext.Add($Global:DataObject."$prop")
    $getter = [scriptblock]::Create("Write-Output `$DataContext['$i'] -noenumerate")
    $setter = [scriptblock]::Create("param(`$val) return `$DataContext['$i']=`$val")
    $State | Add-Member -Name $prop -MemberType ScriptProperty -Value  $getter -SecondValue $setter

    }
    
}

Function Start-RunspaceTask{
    [CmdletBinding()]
    Param([Parameter(Mandatory=$True,Position=0)][ScriptBlock]$ScriptBlock,
          [Parameter(Mandatory=$True,Position=1)][PSObject[]]$ProxyVars)
            
    $Runspace = [RunspaceFactory]::CreateRunspace($Global:InitialSessionState)
    $Runspace.ApartmentState = 'STA'
    $Runspace.ThreadOptions  = 'ReuseThread'
    $Runspace.Open()
    ForEach($Var in $ProxyVars){$Runspace.SessionStateProxy.SetVariable($Var.Name, $Var.Variable)}
    $Thread = [PowerShell]::Create('NewRunspace')
    $Thread.AddScript($ScriptBlock) | Out-Null
    $Thread.Runspace = $Runspace
    [Void]$Jobs.Add([PSObject]@{ PowerShell = $Thread ; Runspace = $Thread.BeginInvoke() })
}

function Async($scriptBlock){
    Start-RunspaceTask $scriptBlock @([PSObject]@{ Name='DataContext' ; Variable=$DataContext},[PSObject]@{Name="State"; Variable=$State},[PSObject]@{Name = "SyncHash";Variable = $SyncHash})
}

function Start-BackgroundTasks {
    $Global:SyncHash = [HashTable]::Synchronized(@{})
    $SyncHash.Window = $Window
    $SyncHash.CleanupJobs = $True
    $Global:Jobs = [System.Collections.ArrayList]::Synchronized([System.Collections.ArrayList]::new())
    $Global:InitialSessionState = [initialsessionstate]::CreateDefault()
    
    
    Get-ChildItem Function: | Where-Object {$_.name -notlike "*:*"} |  Select-Object name -ExpandProperty name | ForEach-Object {
        $Definition = Get-Content "function:$_" -ErrorAction Stop
        $SessionStateFunction = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList "$_", $Definition
        $Global:InitialSessionState.Commands.Add($SessionStateFunction)
    }
    
    $Window.DataContext = $Global:DataContext
    $Window.Add_Closed({
        Write-Verbose 'Halt runspace cleanup job processing'
        $SyncHash.CleanupJobs = $False
    })
    
    $JobCleanupScript = {
        Do
        {
            ForEach($Job in $Jobs)
            {
                If($Job.Runspace.IsCompleted)
                {
                    [Void]$Job.Powershell.EndInvoke($Job.Runspace)
                    $Job.PowerShell.Runspace.Close()
                    $Job.PowerShell.Runspace.Dispose()
                    $Job.Powershell.Dispose()
                    $Jobs.Remove($Job)
                }
            }
            Start-Sleep -Seconds 1
        }
        While ($SyncHash.CleanupJobs)
    }
    
    Start-RunspaceTask $JobCleanupScript @([PSObject]@{ Name='Jobs' ; Variable=$Jobs })
}