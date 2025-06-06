Add-Type -AssemblyName System.Windows.Forms

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Forensic Tool Interface"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"

# Button to select a file
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

# Text field to display the selected file path
$textBoxFile = New-Object System.Windows.Forms.TextBox
$textBoxFile.Location = New-Object System.Drawing.Point(120, 22)
$textBoxFile.Size = New-Object System.Drawing.Size(400, 20)
$form.Controls.Add($textBoxFile)

# List of forensic tools
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

# Button to check if the tool is installed
$buttonCheck = New-Object System.Windows.Forms.Button
$buttonCheck.Text = "Check Installation"
$buttonCheck.Location = New-Object System.Drawing.Point(20,100)
$form.Controls.Add($buttonCheck)

# Button to install the tool
$buttonInstall = New-Object System.Windows.Forms.Button
$buttonInstall.Text = "Install Tool"
$buttonInstall.Location = New-Object System.Drawing.Point(160,100)
$buttonInstall.Visible = $false
$form.Controls.Add($buttonInstall)

# Function to check if the tool is installed
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

# Click event for the check button
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

# Click event for the install button
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

# Button to run the tool
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

    # Check if the tool is installed
    if (-not (CheckIfToolExists $selectedTool)) {
        [System.Windows.Forms.MessageBox]::Show("The selected tool is not installed!", "Error")
        return
    }

    # Run the tool
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

# Show the form
$form.ShowDialog()
