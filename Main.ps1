#Load required libraries
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing 
Import-Module $PSScriptRoot\Modules\MultiThreadingFunctions.psm1 -Force
Import-Module $PSScriptRoot\Modules\Functionality.psm1 -Force


#Load required dll libraries
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$assemblyLocation = Join-Path -Path $scriptPath -ChildPath .\Binary
foreach ($assembly in (Get-ChildItem $assemblyLocation -Filter *.dll)) {
    [System.Reflection.Assembly]::LoadFrom($assembly.FullName) | out-null
}

#Read XAML form
$Xaml = Get-Content -Path $PSScriptRoot\Xaml\Main.xaml
$Global:Window = [Windows.Markup.XamlReader]::Parse($Xaml)
[xml]$Xml = $Xaml

#Load control variables
$Xml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")  | ForEach-Object { 
	New-Variable  -Name $_.Name -Value $Window.FindName($_.Name) -Force -Scope Script
}



#-------------------------------------------------------------#
#----Data Binding Setup---------------------------------------#
#-------------------------------------------------------------#
$Global:State = [PSCustomObject]@{}
$Global:DataObject =  Get-Content -Path $PSScriptRoot\Json\DataContext.json | ConvertFrom-Json
$Global:DataContext = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
FillDataContext @("CurrentUser","Time","ViewIndex")

#Index on set-binding references the position in the array on the line above
Set-Binding -Target $Label1 -Property $([System.Windows.Controls.Label]::ContentProperty) -Index 0 -Name "CurrentUser"
Set-Binding -Target $Label2 -Property $([System.Windows.Controls.Label]::ContentProperty) -Index 1 -Name "Time"
Set-Binding -Target $ViewPort -Property $([System.Windows.Controls.TabControl]::SelectedIndexProperty) -Index 2 -Name "ViewIndex"

Start-BackgroundTasks

#-------------------------------------------------------------#
#----Logic------------------------------------------------#
#-------------------------------------------------------------#
$FlyoutButton_ActiveDirectory.Add_Click({
    $State.ViewIndex = 0
    $DrawerToggle.IsChecked = $false
})
$FlyoutButton_Bookmarks.Add_Click({
    $State.ViewIndex = 2
    $DrawerToggle.IsChecked = $false
})
$FlyoutButton_History.Add_Click({
    $State.ViewIndex = 1
    $DrawerToggle.IsChecked = $false
})


#Actions that will be performed once UI has loaded
$MainWindow.Add_ContentRendered({
    Get-CurrentTime
    $State.CurrentUser = Get-CurrentUser
    $ToolBox_Icon.Source = "$PSScriptRoot\images\Toolbox.png"
})

$Window.ShowDialog() | Out-Null