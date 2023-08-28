# wordpress-lemp

This repo includes a script to create wordpress site using lemp stack.

## How to run this script
To run any script, we have to make it executable.
```console
chmod +x script.sh
```

Now run given command
```console
sudo ./script.sh SITE_NAME
```

### Subcommands

To start/Restart the containers,
```
sudo ./script.sh SITE_NAME enable
```
To Stop the containers,
```
sudo ./script.sh SITE_NAME disable
```
To Delete the containers,
```
./script.sh SITE_NAME delete
```
