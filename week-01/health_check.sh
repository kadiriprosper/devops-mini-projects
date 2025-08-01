#!/bin/bash


echo "Welcome $(whoami) to Health Check 1.0 -- alpha🩺"
echo
echo "Let's set up some basic things requied for the health check."
echo "----------------------------------------------------------------"
echo "Checking if the script is running as root..."
echo

# Check the user id to ensure the script is run as root
# If not, prompt the user to run it with sudo or as root
# If the user is not root, exit with an error message
# Note: Root has an id of 0
if [ "$(id -u)" -ne 0 ]; then
    echo "⚠️⚠️ This script must be run as root. Please use 'sudo' (Best Option) or switch to the root user."
    exit 1
else
    echo "✅ You are running this script as root."
fi

echo

# Check if the logs directory exists, if not create it

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/../logs"

if [ ! -d LOG_DIR ]
then
    mkdir -p $LOG_DIR
else
    echo "Log directory already exists."
fi

timestamp="$(date +'%Y-%m-%d %H_%M_%S')"

log_file="$LOG_DIR/system_health_$timestamp.log" 

echo "----------------------------------------------------------------"
echo "----------------------------------------------------------------"

# Start Report
{
# Display the current time

echo "Health Check started at:"
echo "Date: $(date +'%a %d %b, %Y')"
echo "Time: $(date +'%H:%M:%S %p')"
echo "================================================================"
echo "----------------------------------------------------------------"


echo "📊 SYSTEM REPORT (Details)"

echo "----------------------------------------------------------------"

# Display the total uptime on of the system
echo "TOTAL UPTIME"
uptime -p | sed 's/up/Total Up Time:/' | sed 's/, /:/'

# Display the operating system information
echo -e "\nOS INFORMATION"
[ -f /etc/os-release ] && grep -E '^NAME=|VERSION=' /etc/os-release || echo "OS information not available."

# echo -e "\n🧠 CPU LOAD:"
# uptime | awk -F'load average:' '{ print "Load Average:" $2 }'

echo -e "\n🧠 AVERAGE CPU LOAD"
uptime | awk -F'load average:' '{ print "Load Average:" $2 }'

# Display the total memory usage
echo -e "\n💾 MEMORY USAGE"
free -h | grep -v Swap

# Display the disk usage
echo -e "\n💾 DISK USAGE"
df -hT | grep -v wslfs | grep -v tmpfs | grep -v overlay | grep -v squashfs | grep -v aufs | grep -v devtmpfs

totalusage=$(df -hT | grep -v wslfs | grep -v tmpfs | grep -v overlay | grep -v squashfs | grep -v aufs | grep -v devtmpfs | awk 'NR==2 {print $6}')

numeric_usage=${totalusage%\%}
if [ "$numeric_usage" -ge 70 ]; then
    echo -e "\n⚠️ WARNING: Disk usage is above 70% (Currently at $totalusage). Please consider cleaning up disk space."
else
    echo -e "\n✅ Disk usage is within acceptable limits ($totalusage)."
fi

# Display Top 5 CPU-Consuming processes
# The command list the processes sorted by CPU usage showing only pid, ppid, command, memory usage, and CPU usage
# The output is limited to the top 5 processes
echo -e "\n🔍 TOP 5 CPU-CONSUMING PROCESSES"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -n 6

# Display Top 5 Memory-Consuming processes
# The command list the processes sorted by CPU usage showing only pid, ppid, command, memory usage, and CPU usage
# The output is limited to the top 5 processes
echo -e "\n🔍 TOP 5 MEMORY-CONSUMING PROCESSES"
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 6

# Display the network instances
echo -e "\n🌐 NETWORK INTERFACES:"
ip -brief address show && echo && ip -brief link show

# Display the active network connections
# The command lists the active network connections, showing the protocol, local address, foreign address, and the state of the connection. The output is limited to the top 10 connections.
echo -e "\n🔗 ACTIVE NETWORK CONNECTIONS (Top 10):"
netstat -tunap | head -n 10

# Display the system's hostname
echo -e "\n🏷️ HOSTNAME:"
hostname

echo '----------------------------------------------------------------'
echo "📁 Saving report to log file..."

echo -e "\n✅ REPORT COMPLETED!"
echo "📁 Log file saved to: $log_file"

} | tee "$log_file"


# End of Report
