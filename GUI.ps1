    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "My PowerShell GUI"
    $button = New-Object System.Windows.Forms.Button
    $button.Text = "Click Me!"
    $button.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Button Clicked!") })
    $form.Controls.Add($button)
    $form.ShowDialog()