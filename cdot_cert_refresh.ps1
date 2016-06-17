[CmdletBinding()]
Param(
 [Parameter(Mandatory=$True,Position=1)]
   [string]$Cluster,
	
   [Parameter(Mandatory=$True)]
   [int]$ExpireDays,
   
   [Parameter(Mandatory=$True)]
   [string]$UserName,
   
   [Parameter(Mandatory=$True)]
   [string]$Password
)

$securepw = ConvertTo-SecureString $Password -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential ($UserName,$securepw)

Connect-NcController -Name $Cluster -Credential $credential

$CERT = Get-NcSecurityCertificate

$CERT | foreach {
	Remove-NcSecurityCertificate -CommonName $_.CommonName -Type $_.Type -SerialNumber $_.SerialNumber -CertificateAuthority $_.CertificateAuthority -Vserver $_.Vserver -Confirm:$false
	
	$NEWCERT="New-NcSecurityCertificate -CommonName " + $_.CommonName + " -Type " + $_.Type + "	-ExpireDays $ExpireDays -Vserver " + $_.Vserver + " -HashFunction " + $_.HashFunction + " -Size " + $_.Size + " -Country " + $_.Country
	
	if ($_.State) { $NEWCERT=$NEWCERT + "  -State " + $_.State  } 
	if ($_.Locality) { $NEWCERT=$NEWCERT + "  -Locality " + $_.Locality } 
	if ($_.Organization) { $NEWCERT=$NEWCERT + "  -Organization " + $_.Organization } 
	if ($_.OrganizationUnit) { $NEWCERT=$NEWCERT + "  -OrganizationUnit " + $_.OrganizationUnit } 
	if ($_.EmailAddress) { $NEWCERT=$NEWCERT + " -EmailAddress " + $_.EmailAddress } 

	Invoke-Expression $NEWCERT
}