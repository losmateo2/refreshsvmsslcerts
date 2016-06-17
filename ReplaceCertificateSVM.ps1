
$Cluster = "Cluster.domain.com"

$CertDays = "10"

#Certificate settings
$CertSize = "2048"
$CertCountry = "SE"
$CertState = "STATE"
$CertOrg = "Organisation"
$CertOrgUnit = "Unit"
$CertEmail = "mail@domain.com"
$CertExpireDays = "1825"
$CertHashFunction = "SHA256"

#Clean up 
$OldCerts = ""
$NewCert = ""
$CertCount = ""
$module =""

#Testing for DataOntap module needed for the script.
$module = Get-Module DataOntap
if ($module -eq $null)
{
import-module DataOntap
try 
	{ 
	$module = Get-Module DataOntap
	if ($module -eq $null) { throw }
	}
catch [Exception]
	{
	Write-Host 'This script needs DataOntap module!!' -BackgroundColor Red
	BREAK
	}
}
$module =""


$userName = Read-Host ("UserName to connect to NetApp controllers")  
$passwd = Read-Host ("Password for " + $userName) -AsSecureString:$true
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $userName,$passwd

Connect-NcController -Name $Cluster -Credential $cred -ErrorAction Stop


$OldCerts = Get-NcSecurityCertificate | Where-Object  ExpirationDateDT -lt (get-date).AddDays($CertDays)
$CertCount = $OldCerts.count
if ($CertCount -notlike "0")
    {
    CLS
     Write-Host "Found $CertCount Certificates on cluster $cluster."
    }
    ELSE
    {
    Write-Host "NO Certificates on $Cluster is in the range for replacing!"  
    Write-Host "Increase the value of 'CertDays' from $CertDays and try again."  
    EXIT
    }  


$choice =""
while ($choice -notmatch "[y|n]")
{
    Write-Host "Certificates on this/these SVMs will be replaced"  
    Write-Host $OldCerts.vserver
    $choice = read-host "Do you want to continue? (Y/N)"
}

if ($choice -eq "y") #Remove the old cert create a new cert. Create the new cert and modify SSL settings for the SVM.
{
 ForEach ($OldCert in $OldCerts)
   {
     Remove-NcSecurityCertificate -CommonName $OldCert.CommonName -Type $OldCert.Type  -SerialNumber $OldCert.SerialNumber -CertificateAuthority $OldCert.CertificateAuthority -Vserver $OldCert.Vserver -Confirm:$false
         New-NcSecurityCertificate -CommonName $OldCert.CommonName -Type $OldCert.Type  -Vserver $OldCert.Vserver -size $CertSize -country $CertCountry -state $CertState -locality "" -organization $CertOrg -OrganizationUnit $CertOrgUnit -EmailAddress $CertEmail -ExpireDays $CertExpireDays -HashFunction $CertHashFunction 
            
     $NewCert = Get-NcSecurityCertificate -vserver $OldCert.Vserver
         Set-NcSecuritySsl -Vserver $NewCert.Vserver -CertificateAuthority $NewCert.CertificateAuthority  -CertificateSerialNumber $NewCert.SerialNumber -CommonName $NewCert.CommonName -EnableServerAuthentication $True -EnableClientAuthentication $False
   }
}
    
Else 
{
write-host 'You didnt want to replace certificates script exits!'
  EXIT
}
