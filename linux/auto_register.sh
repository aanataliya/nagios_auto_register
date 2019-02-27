#manually start service for selinux by setenforce
if rpm -qa | egrep -qw nrpe; then
echo "nrpe already installed. checking if selinux is enabled.."
Enforce=$(getenforce)
if [[ "$Enforce" != "Disabled" ]]
then
   if [[ $(ps -ef | grep -v grep | grep nrpe | wc -l) -eq 0 ]]
   then
        echo "nrpe not running. starting nrpe with setenforce 0"
        sudo setenforce 0
        systemctl restart nrpe.service
   else
        echo "nrpe already running"
   fi
fi
fi

#variables
LOGFILE_PATH=/usr/local/nagios/logs/auto_register.log
OUTXML_PATH=/usr/local/nagios/register_out.xml
INPUTXML_PATH=/usr/local/nagios/register.xml

echo "starting auto registration $(date)" >> $LOGFILE_PATH
rm -rf /usr/local/nagios/register_out.xml
IP="$(hostname -I | awk 'NR==1{print $1}')"
echo "client ip is $IP"  >> $LOGFILE_PATH;
INSTANCE_ID="$(curl http://169.254.169.254/latest/meta-data/instance-id)"
echo "instance id is $INSTANCE_ID" >> $LOGFILE_PATH

AVAIL_ZONE="$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone)"
REGION="$(echo $AVAIL_ZONE | sed 's/[a-z]$//')"
echo "region is $REGION"

#identify if this is SS instance or AMS instance
#HOSTNAME="$(curl http://169.254.169.254/latest/meta-data/hostname)"
#if [[ $HOSTNAME != *""amazonaws.com* ]]
#then
        # this is NOT AMS instance, read application tag name and send it with XML
        APP_NAME="$(aws ec2 describe-tags --filters Name=resource-type,Values=instance Name=resource-id,Values=$INSTANCE_ID Name=key,Values=Application --region $REGION --query 'Tags[?Key==`Application`].Value' --output text)"
        echo "app name is $APP_NAME"
        sed 's/<ip>/<ip>'$IP'/g; s/<region>/<region>'$REGION'/g; s/<app_name>/<app_name>'$APP_NAME'/g; s/<instance_id>/<instance_id>'$INSTANCE_ID'/g; s/<platform>/<platform>Linux/g' $INPUTXML_PATH >> $OUTXML_PATH
#else
#        echo "This is AMS Instance. Region is $REGION"
#        sed 's/<ip>/<ip>'$IP'/g; s/<region>/<region>'$REGION'/g; s/<instance_id>/<instance_id>'$INSTANCE_ID'/g; s/<platform>/<platform>Linux/g' $INPUTXML_PATH >> $OUTXML_PATH
#fi

NS="$(grep '<ns>' /usr/local/nagios/register.xml | awk -F'<ns>|</ns>' '{print $2}')"
for i in $(echo $NS | sed "s/,/ /g")
{
    echo "nagios server ip is $i" >> $LOGFILE_PATH;
    curl -i -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: application/xml" -d @$OUTXML_PATH http://$i/register/me >> $LOGFILE_PATH
}
