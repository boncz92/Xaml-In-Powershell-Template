function Show-DialogBox {
    [CmdletBinding()]
    param (
        $Text,
        $Title
    )
    $Type_OkCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
    $Type_Ok      = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
     
    $Result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($Window,"$Title","$Text",$Type_Ok)
}

function Get-CurrentTime {
    Async{
        while (0 -ne 1) {
            $DateQ1 = (Get-Date -UFormat "%a").ToString()
            $DateQ2 = (Get-Date -Format "MM/dd/yyyy HH:mm").ToString()
            $State.Time = "$DateQ1 - $DateQ2"
            Start-Sleep -Seconds 5
        }
    }
}

function Get-CurrentUser {
    return $env:UserName
}

function UpdatePrinterCSV {
    Get-ADObject -LDAPFilter "(objectCategory=printQueue)" -Properties printerName, shortServerName, portName, location |`
    Select-Object printerName,shortServerName, @{N="portName";E={$_.portName -join ","}}, location |`
    Export-Csv -Path "$PSScriptRoot\Printer.csv" -NoTypeInformation
}