Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# interface utilisateur
function Show-UI {
    # fenêtre de l'interface
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Host-Based Intruction Detection System"
    $form.Size = New-Object System.Drawing.Size(400, 320)
    $form.StartPosition = "CenterScreen"
    
    # création du champ de saisie pour le chemin du dossier à surveiller
    $labelPath = New-Object System.Windows.Forms.Label
    $labelPath.Text = "Chemin du dossier à surveiller :"
    $labelPath.AutoSize = $true
    $labelPath.Location = New-Object System.Drawing.Point(10,20)
    
    $textBoxPath = New-Object System.Windows.Forms.TextBox
    $textBoxPath.Size = New-Object System.Drawing.Size(250, 20)
    $textBoxPath.Location = New-Object System.Drawing.Point(10, 50)

    $buttonBrowse = New-Object System.Windows.Forms.Button
    $buttonBrowse.Text = "Parcourir..."
    $buttonBrowse.Location = New-Object System.Drawing.Point(270, 48)
    
    $buttonBrowse.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Sélectionnez un dossier à surveiller"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $textBoxPath.Text = $dialog.SelectedPath
        }
    })

    # création du champ de saisie pour l'adresse mail sur laquelle envoyer l'email d'alerte
    $labelEmail = New-Object System.Windows.Forms.Label
    $labelEmail.Text = "Adresse Mail de destination :"
    $labelEmail.AutoSize = $true
    $labelEmail.Location = New-Object System.Drawing.Point(10,90)
    
    $textBoxEmail = New-Object System.Windows.Forms.TextBox
    $textBoxEmail.Size = New-Object System.Drawing.Size(250, 20)
    $textBoxEmail.Location = New-Object System.Drawing.Point(10, 110)

    $labelIP = New-Object System.Windows.Forms.Label
    $labelIP.Text = "Adresse IP (machine à surveiller) :"
    $labelIP.AutoSize = $true
    $labelIP.Location = New-Object System.Drawing.Point(10,140)
    
    $textBoxIP = New-Object System.Windows.Forms.TextBox
    $textBoxIP.Size = New-Object System.Drawing.Size(250, 20)
    $textBoxIP.Location = New-Object System.Drawing.Point(10, 160)

    $labelRemotePath = New-Object System.Windows.Forms.Label
    $labelRemotePath.Text = "Chemin (machine à surveiller) :"
    $labelRemotePath.AutoSize = $true
    $labelRemotePath.Location = New-Object System.Drawing.Point(10,190)
    
    $textBoxRemotePath = New-Object System.Windows.Forms.TextBox
    $textBoxRemotePath.Size = New-Object System.Drawing.Size(250, 20)
    $textBoxRemotePath.Location = New-Object System.Drawing.Point(10, 210)

    $buttonOk = New-Object System.Windows.Forms.Button
    $buttonOk.Text = "Lancer la surveillance"
    $buttonOk.Size = New-Object System.Drawing.Size(125,20)
    $buttonOk.Location = New-Object System.Drawing.Point(70, 240)

    # assigner les valeurs aux variables rentrées dans les champs de saisie 
    $buttonOk.Add_Click({
        $global:Path = $textBoxPath.Text
        $global:Email = $textBoxEmail.Text
        $global:IP = $textBoxIP.Text
        $global:RemotePath = $textBoxRemotePath.Text
        $form.Close()
    })

    #ajout des différents champ de saisie et label à notre formulaire

    $form.Controls.Add($labelPath)
    $form.Controls.Add($textBoxPath)
    $form.Controls.Add($buttonBrowse)
    $form.Controls.Add($labelEmail)
    $form.Controls.Add($textBoxEmail)
    $form.Controls.Add($labelIP)
    $form.Controls.Add($textBoxIP)
    $form.Controls.Add($labelRemotePath)
    $form.Controls.Add($textBoxRemotePath)
    $form.Controls.Add($buttonOk)

    # afficher l'interface utilisateur
    $form.ShowDialog()
}

# appeler l'interface créée précédemment pour récupérer les valeurs (à l'exécution du script)
Show-UI

# script principal après saisie de l'utilisateur


#fonction permettant d'envoyer un mail
 function sendMail {
        param (
            [string]$file,
            [string]$toEmail
        )
        #configuration des paramètres nécessaires à l'envoi de mail
        $smtpServer = "smtp.gmail.com"
        $from = "yourmail.com"
        $subject = "Fichier compromis / suspect"
        $body = "Le fichier $file n'est pas integre"
        $username = "username"
        #récupération du mot de passe stocker en local de manière sécurisée grâce à ConvertTo-SecureString
        $securePassword = Get-Content "yourpath" | ConvertTo-SecureString
        $smtpPort = 587
        #connexion au serveur SMTP avec l'identifiant / mot de passe
        $credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

        #envoi du mail
        Send-MailMessage -SmtpServer $smtpServer -Port $smtpPort -From $from -To $toEmail -Subject $subject -Body $body -Credential $credential -UseSsl
    }

#fonction permettant de regarder si le contenu du fichier est le même qu'avant
function CheckFile {
        param (
            [string]$file
        )
        Write-Output "Analyse"

        #extrait du hash du fichier avec le contenu AVANT
        $local:hash = Get-FileHash $file | Select-Object -ExpandProperty Hash
        $local:hashnew = $hash

        #toutes les secondes, le hash du contenu d'AVANT et comparé avec le hash du contenu APRES, pour voir s'il est égal
        while ($hash -eq $hashnew) {
            Start-Sleep -Seconds 1
            $local:hashnew = Get-FileHash $file | Select-Object -ExpandProperty Hash
        }
        #lorsque les deux hash ne sont pas égaux car le fichier a été modifié, on sort de la boucle et le mail est envoyé
        sendMail -file $file -toEmail $Email
        Write-Output "$file modified"
        Set-Content -Path log.txt -Value "$file modified"
}

    $allFiles = @{}

#fonction permettant de regarder dans un fichier et de reconnaître les différentes dossiers/fichiers qui s'y trouvent
function CheckFolder {
        param (
            [string]$Path2
        )
        $list = Get-ChildItem -Path $Path2 -Recurse

        foreach ($element in $list) {
            if (Test-Path $element.FullName -PathType Container) {
                Write-Output "$($element.FullName) est un dossier."
                CheckFolder -Path2 $element.FullName
            } else {
                Write-Output "$($element.FullName) est un fichier"
                $hash = Get-FileHash $($element.FullName) | Select-Object -ExpandProperty Hash
                $allFiles["$($element.FullName)"] = $hash
            }
        }
}

# surveillance locale ou distante
if ($Path -and $Email) {
    # surveillance sur machine locale
    Write-Output "Lancement de la surveillance locale sur $Path"
    $allFiles = @{}
    #lancement de la fonction checkfolder qui va énumérer les différents fichiers/dossiers qui sont dans le dossier à surveiller
    if (Test-Path $Path) {
        if (Test-Path $Path -PathType Container) {
            CheckFolder -Path2 $Path -allFiles $allFiles
        } else {
            $hash = Get-FileHash $Path | Select-Object -ExpandProperty Hash
            $allFiles[$Path] = $hash
        }
    } else {
        Write-Output "Le chemin $Path n'existe pas."
    }

    # boucle de scan continue en arrière plan qui s'exécuté jusqu'à ce que l'utilisateur stoppe l'analyse
    while ($true) {
        foreach ($file in $allFiles.Keys) {
            $hash = Get-FileHash $file | Select-Object -ExpandProperty Hash
            if ($hash -ne $allFiles[$file]) {
                Write-Output "$file modified!"
                sendMail -file $file -toEmail $Email
                $allFiles[$file] = $hash
            }
        }
    }

} elseif ($Email -and $IP -and $RemotePath) {
    # surveillance sur machine distante
    Write-Output "Lancement de la surveillance distante sur $RemotePath"
    $remotePC = $IP
    $remotePathNetwork = "\\$remotePC\$RemotePath"
    
    $allFiles = @{}
    #lancement de la fonction checkfolder qui va énumérer les différents fichiers/dossiers qui sont dans le dossier à surveiller
    if (Test-Path $remotePathNetwork) {
        if (Test-Path $remotePathNetwork -PathType Container) {
            CheckFolder -Path2 $remotePathNetwork -allFiles $allFiles
        } else {
            $hash = Get-FileHash $remotePathNetwork | Select-Object -ExpandProperty Hash
            $allFiles[$remotePathNetwork] = $hash
        }
    } else {
        Write-Output "Le chemin distant $remotePathNetwork n'existe pas."
    }

    # boucle de scan continue en arrière plan qui s'exécuté jusqu'à ce que l'utilisateur stoppe l'analyse
    while ($true) {
        foreach ($file in $allFiles.Keys) {
            $hash = Get-FileHash $file | Select-Object -ExpandProperty Hash
            if ($hash -ne $allFiles[$file]) {
                Write-Output "$file modified!"
                sendMail -file $file -toEmail $Email
                $allFiles[$file] = $hash
            }
        }
    }

} else {
    Write-Output "Veuillez fournir soit un chemin local et un e-mail, soit une IP et un chemin distant."
}


# SIG # Begin signature block
#Signature
# SIG # End signature block
