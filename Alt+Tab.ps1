Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class Win32API {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@ -ErrorAction Stop

function Get-OpenWindows {
    $windowList = New-Object System.Collections.ArrayList

    $enumDelegate = [Win32API+EnumWindowsProc]{
        param([IntPtr] $hWnd, [IntPtr] $lParam)

        if (-not [Win32API]::IsWindowVisible($hWnd)) { return $true }

        $length = [Win32API]::GetWindowTextLength($hWnd)
        if ($length -eq 0) { return $true }

        $builder = New-Object System.Text.StringBuilder ($length + 1)
        [Win32API]::GetWindowText($hWnd, $builder, $builder.Capacity) | Out-Null
        $title = $builder.ToString()

        if (![string]::IsNullOrWhiteSpace($title)) {
            $excludedTitles = @(
                "Program Manager",
                "Windows Input Experience"
            )

            if ($excludedTitles -notcontains $title) {
                $windowList.Add([PSCustomObject]@{
                    Handle = $hWnd
                    Title  = $title
                }) | Out-Null
            }
        }

        return $true
    }

    [Win32API]::EnumWindows($enumDelegate, [IntPtr]::Zero) | Out-Null
    return $windowList
}

function Show-WindowSelector {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object Windows.Forms.Form
    $form.Text = "Open Windows/Apps"
    $form.Width = 600
    $form.Height = 380
    $form.StartPosition = "CenterScreen"

    $listBox = New-Object Windows.Forms.ListBox
    $listBox.Width = 560
    $listBox.Height = 300
    $listBox.Location = New-Object Drawing.Point(10,10)
    $listBox.Anchor = "Top, Left, Right"
    $listBox.SelectionMode = "One"
    $form.Controls.Add($listBox)

    $cancelButton = New-Object Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Width = 560
    $cancelButton.Height = 30
    $cancelButton.Location = New-Object Drawing.Point(10,320)
    $form.Controls.Add($cancelButton)

    $windowMap = @{}

    function Update-WindowList {
        $openWindows = Get-OpenWindows

        $currentTitles = @($listBox.Items) | Sort-Object
        $newTitles = $openWindows.Title | Sort-Object

        if (-not ($currentTitles -eq $newTitles)) {
            $listBox.Items.Clear()
            $windowMap.Clear()
            foreach ($win in $openWindows) {
                $listBox.Items.Add($win.Title) | Out-Null
                $windowMap[$win.Title] = $win.Handle
            }

            if ($listBox.Items.Count -eq 0) {
                $listBox.Items.Add("[No open windows found]") | Out-Null
            }
        }
    }

    # When the user selects an item, bring that window to front immediately
    $listBox.Add_SelectedIndexChanged({
        $selected = $listBox.SelectedItem
        if ($selected -and $windowMap.ContainsKey($selected)) {
            $hWnd = $windowMap[$selected]
            [Win32API]::ShowWindow($hWnd, 9) | Out-Null  # SW_RESTORE
            [Win32API]::SetForegroundWindow($hWnd) | Out-Null
        }
    })

    $cancelButton.Add_Click({
        $form.Close()
    })

    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 2000
    $timer.Add_Tick({ Update-WindowList })
    $timer.Start()

    Update-WindowList

    $form.ShowDialog()
}

Show-WindowSelector
