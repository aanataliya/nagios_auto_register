$ipV4 = Test-Connection -ComputerName (hostname) -Count 1  | Select -ExpandProperty IPV4Address;
$register_out_xml=(Get-Content C:/nagios/register.xml).replace('<ip>', '<ip>'+$ipV4.IPAddressToString);

$wc = New-Object system.Net.WebClient;
$instance_id=$wc.downloadString("http://169.254.169.254/latest/meta-data/instance-id")

if($instance_id)
{
    Write "Found instance Id. Proceeding POST request." >> C:/nagios/logs/auto_register.log

    $REGION=$wc.downloadString("http://169.254.169.254/latest/meta-data/placement/availability-zone/")
    $REGION=$REGION.Substring(0,$REGION.Length-1)
    Write "region is $REGION"

    $comm= iex "& aws ec2 describe-tags --filters Name=resource-type,Values=instance Name=resource-id,Values=$INSTANCE_ID Name=key,Values=Application --region $REGION | ConvertFrom-Json"
    $app_name= $comm.Tags | where { $_.Key -eq "Application" } | Select -ExpandProperty Value
    write "app_name is $app_name"

    $register_out_xml=$register_out_xml.replace('<instance_id>', '<instance_id>'+$instance_id);
    $register_out_xml=$register_out_xml.replace('<platform>', '<platform>Windows');
    $register_out_xml=$register_out_xml.replace('<app_name>', '<app_name>'+$app_name);
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]";
    $headers.Add("Accept", 'application/xml');

    [xml]$register_xml = Get-Content 'C:/nagios/register.xml'
    $NS = $register_xml.SelectSingleNode("//ns").innerText
    $register_out_xml | Out-File 'C:/nagios/register_out.xml';
    $NS.Split(",") | ForEach {
    Invoke-RestMethod -Uri http://$_/register/me -Method Post -Headers $headers -Body $register_out_xml >> C:/nagios/logs/auto_register.log
    }
}
else
{
    Write "Failed to get Instance Id." >> C:/nagios/logs/auto_register.log
}
