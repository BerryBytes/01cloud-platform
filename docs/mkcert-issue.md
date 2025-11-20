### Adding mkcert CAroot for snapd firefox
After running `mkcert -install` you may (not very often) encounter issue regarding refused connection to your host. This is due to firefox being installed as a snap package. To bypass this  create a `ceretificates` folder inside `/var/lib/snapd/deskto/`  and copy the `CAroot` file inside the `certificates` folder.
```bash
# create folder if not present
sudo mkdir -p /var/lib/snapd/desktop/certificates/

# copy the CAroot file
sudo cp "$(mkcert -CAROOT)/rootCA.pem" /var/lib/snapd/desktop/certificates/
sudo update-ca-certificates
```