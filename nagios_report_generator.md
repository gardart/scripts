Generates status report for various Nagios information like check latency, execution time, config settings, running processes....
Useful for troubleshooting issues with Nagios server.

Run with Nagios users crontab:
5 * * * * /opt/scripts/nagios_report_generator.sh > /var/log/nagios/scheduler/scheduler_$(date +\%Y\%m\%d_\%H:\%M:\%S\%z).log 2>&1
