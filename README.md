# Nagios auto register

AWS Auto scaling group dynamically creates and deletes instances in real time. Nagios Core has to dynamically and instantly know which instance is created so that it can monitor new instances in real time. Nagios client instances will use HTTP REST APIs to register itself to nagios server whenver new instance is created under Auto scaling group.

These scripts are used for automatically sending POST request to nagios server to register themselves in dynamica AWS Auto Scaling environment.

This repository is just one part of bigger Nagios monitoring solution. Please refer below link to read details about full solution.

https://web-need.blogspot.com/2019/02/how-to-use-nagios-to-monitor-services.html
