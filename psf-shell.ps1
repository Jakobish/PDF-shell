Add-Type -AssemblyName System.Windows.Forms

# יצירת טופס ראשי
$form = New-Object System.Windows.Forms.Form
$form.Text = "Forensic Tool Interface"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"

# כפתור בחירת קובץ
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.Filter = "All Files (*.*)| *.*"
$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Text = "Browse File"
$buttonBrowse.Location = New-Object System.Drawing.Point(20,20)
$buttonBrowse.Add_Click({
    $fileDialog.ShowDialog()
    $textBoxFile.Text = $fileDialog.FileName
})
$form.Controls.Add($buttonBrowse)

# שדה טקסט להצגת הנתיב שנבחר
$textBoxFile = New-Object System.Windows.Forms.TextBox
$textBoxFile.Location = New-Object System.Drawing.Point(120, 22)
$textBoxFile.Size = New-Object System.Drawing.Size(400, 20)
$form.Controls.Add($textBoxFile)

# רשימת כלים פורנזיים
$labelTools = New-Object System.Windows.Forms.Label
$labelTools.Text = "Select Tool:"
$labelTools.Location = New-Object System.Drawing.Point(20, 60)
$form.Controls.Add($labelTools)

$comboTools = New-Object System.Windows.Forms.ComboBox
$comboTools.Location = New-Object System.Drawing.Point(120, 58)
$comboTools.Size = New-Object System.Drawing.Size(400, 20)
$comboTools.Items.Add("ExifTool")
$comboTools.Items.Add("pdf-parser.py")
$comboTools.Items.Add("strings")
$comboTools.SelectedIndex = 0
$form.Controls.Add($comboTools)

# כפתור לבדיקה אם הכלי מותקן
$buttonCheck = New-Object System.Windows.Forms.Button
$buttonCheck.Text = "Check Installation"
$buttonCheck.Location = New-Object System.Drawing.Point(20,100)
$form.Controls.Add($buttonCheck)

# כפתור התקנה
$buttonInstall = New-Object System.Windows.Forms.Button
$buttonInstall.Text = "Install Tool"
$buttonInstall.Location = New-Object System.Drawing.Point(160,100)
$buttonInstall.Visible = $false
$form.Controls.Add($buttonInstall)

# פונקציה לבדוק אם כלי מותקן
Function CheckIfToolExists {
    param ($toolName)
    try {
        if ($toolName -eq "pdf-parser.py") {
            $result = & python -c "import pdfparser" 2>$null
            return $?
        }
        $result = Get-Command $toolName -ErrorAction SilentlyContinue
        return $result -ne $null
    } catch {
        return $false
    }
}

# לחיצה על כפתור בדיקה
$buttonCheck.Add_Click({
    $selectedTool = $comboTools.SelectedItem
    if (CheckIfToolExists $selectedTool) {
        [System.Windows.Forms.MessageBox]::Show("$selectedTool is installed!", "Check Result")
        $buttonInstall.Visible = $false
    } else {
        [System.Windows.Forms.MessageBox]::Show("$selectedTool is NOT installed!", "Check Result")
        $buttonInstall.Visible = $true
    }
})

# התקנת הכלי אם חסר
$buttonInstall.Add_Click({
    $selectedTool = $comboTools.SelectedItem
    $confirmation = [System.Windows.Forms.MessageBox]::Show("Install $selectedTool?", "Installation", "YesNo")
    if ($confirmation -eq "Yes") {
        [System.Windows.Forms.MessageBox]::Show("Installing $selectedTool ...", "Installation")
        if ($selectedTool -eq "ExifTool") {
            Start-Process -NoNewWindow -Wait -FilePath "choco" -ArgumentList "install exiftool -y"
        } elseif ($selectedTool -eq "pdf-parser.py") {
            Start-Process -NoNewWindow -Wait -FilePath "pip" -ArgumentList "install pdf-parser"
        } else {
            Start-Process -NoNewWindow -Wait -FilePath "winget" -ArgumentList "install $selectedTool"
        }
        [System.Windows.Forms.MessageBox]::Show("Installation completed!", "Done")
        $buttonInstall.Visible = $false
    }
})

# כפתור הפעלת הכלי
$buttonRun = New-Object System.Windows.Forms.Button
$buttonRun.Text = "Run Analysis"
$buttonRun.Location = New-Object System.Drawing.Point(20,140)
$buttonRun.Add_Click({
    $selectedTool = $comboTools.SelectedItem
    $filePath = $textBoxFile.Text
    if ($filePath -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Please select a file!")
        return
    }

    # בדיקת כלי
    if (-not (CheckIfToolExists $selectedTool)) {
        [System.Windows.Forms.MessageBox]::Show("The selected tool is not installed!", "Error")
        return
    }

    # הרצת הכלי
    $output = ""
    try {
        if ($selectedTool -eq "pdf-parser.py") {
            $output = & python pdf-parser.py $filePath
        } else {
            $output = & $selectedTool $filePath
        }
    } catch {
        $output = "Error running tool: $_"
    }
    [System.Windows.Forms.MessageBox]::Show($output, "Analysis Result")
})
$form.Controls.Add($buttonRun)

# הפעלת הטופס
$form.ShowDialog()
