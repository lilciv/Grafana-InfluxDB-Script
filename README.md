# Grafana and InfluxDB Installer Script

This script will install Docker, Docker Compose, and create containers for Grafana, and InfluxDB.
This script is designed for the Rust Server owner community in order to simplify the setup of Rust Server Metrics:
https://github.com/Pinkstink-Rust/Rust-Server-Metrics


# Prerequisites
- Linux VPS - I recommend **Hetzner**. They are cheap and reliable. Ubuntu Server 20.04 or 22.04 is the **required** OS. Other OS choices will not work at this time.
- If you plan on running this InfluxDB with more than one Rust server, I recommend increasing the server storage, as you may run out.
- Domain Name with two DNS Records - one for Grafana (eg. grafana.example.com) and one for InfluxDB (eg. influx.example.com) - These two records should point to your VPS public IPv4 address. Cloudflare proxying is fine for the Grafana record, but be sure to use DNS only for the Influx one.
- Firewall rules (if applicable) allowing inbound access to TCP ports **80, 443, and 8086**
- Basic knowledge of Linux (How to SSH)

# How To Use
1. SSH to your VPS and run the following command **AS ROOT, not with sudo!**
- ```bash <(curl -s https://raw.githubusercontent.com/lilciv/Grafana-InfluxDB-Script/main/grafana-influx.sh)```
2. Enter a **secure** InfluxDB username and password.
3. Enter your Grafana domain as well as your InfluxDB Domain (eg. grafana.example.com and influx.example.com)
4. Ensure acme.sh is able to succesfully obtain your certificate. If it is not, make sure your firewall ports are opened and try again. This certificate will auto-renew and should not require additional action on your end.
5. At this point, your setup should be complete. Please follow the Rust Server Metrics instructions to proceed. You should begin at **Step 6**: https://github.com/Pinkstink-Rust/Rust-Server-Metrics
	- Note: Your database URL for Rust Server Metrics will be your InfluxDB subdomain with port 8086 - eg. `http(s)://influx.example.com:8086`.
  - Note: The InfluxDB datasource is automatically provisioned to Grafana, so you only need to import the latest RSM dashboard

## FAQ
**What's my database called?**
- The installation script creates a database called **`db01`**
	
**I forgot my database username or password! What do I do?**
- Execute the command **`docker exec InfluxDB /usr/bin/env`** to see this information. It will show the database name, username, and password.
- NOTE: You should use the `INFLUXDB_USER` and `INFLUXDB_USER_PASSWORD`, not the ADMIN credentials when setting up Rust Server Metrics! The admin credentials should only be used if adjusting the retention policy. The standard user has read and write permissions to the `db01` database. Database admin credentials are not needed and not recommended to use for standard access.

**What is the InfluxDB Retention Policy?**
- This will create a 12-week Retention Policy, along with a 24-hour Shard Group Duration as per the Rust Server Metrics recommendations.
- If you would like to change the retention policy to something else, you can execute the following command (4 week example): `docker exec InfluxDB influx -unsafeSsl -ssl -username influxadmin -password INFLUXDB_ADMIN_PASSWORD -execute 'ALTER RETENTION POLICY "autogen" ON "db01" DURATION 4w SHARD DURATION 24h'`

**How do I uninstall this?**
- To uninstall, please run the uninstall script: ```bash <(curl -s https://raw.githubusercontent.com/lilciv/Grafana-InfluxDB-Script/main/grafana-influx-uninstall.sh | tr -d '\r')```

If you have any additional questions, feel free to message me on Discord!
