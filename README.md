# 🚀 **Custom ISO**

**Custom ISO** is a simple project consisting of a few bash scripts. The scripts take an official ISO as input and output an ISO that will launch with a `preseed.cfg` file. This allows you to configure the image to have predefined values ​​in the preseed.

> [!WARNING]
> Please note: the scripts have only been tested with `debian-13.0.0-amd64-netinst.iso`.

## 📦 **Installation**

```bash
git clone https://github.com/6C656C65/custom_iso.git
```

## 🚀 **Usage**

First you need a `preseed.cfg` file. [Here](https://www.debian.org/releases/stable/example-preseed.txt) is an official example for Debian.
An image must also be personalized. [Here](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.0.0-amd64-netinst.iso) for the official iso of `debian 13.0`.

### Build ISO
The `build.sh` script requires `sudo`.
```bash
bash build.sh --in <source_iso> --out <modified_iso> --preseed <preseed_file> [--debug] [--checksum]
# or with key=value style:
bash build.sh in=<source_iso> out=<modified_iso> preseed=<preseed_file> [debug] [checksum]
```

- `<source_iso>` can be a local path **or** a remote URL starting with `https://`.
- You can use the `--checksum` option to calculate and display the checksums of the newly generated ISO.
- The `--debug` option displays detailed messages during the build process.

### Clear temporary files
You can clean up the files that were created during generation with the command below.
```bash
bash clear.sh
```

## 📤 **Upload**
There are also upload scripts to drop the generated iso onto a hypervisor.

### Proxmox
> [!WARNING]
> It is important that the token_id is enclosed in single quotes `'` because it contains a `!`.

```bash
bash upload/proxmox.sh --url <host> --nodes <nodes> --iso <path> --token-id '<id>' [--token-secret <secret>] [--debug]
# or with key=value style:
bash upload/proxmox.sh url=<host> nodes=<nodes> iso=<path> token-id=<id> [token-secret=<secret>] [debug]
```

## 🛠 **Ansible Role**

An Ansible role is available to automate the process of building and uploading a custom ISO to a Proxmox server, as well as creating virtual machines from it.

➡️ You can find the role here: [https://github.com/6C656C65/ansible_roles/tree/main/proxmox](https://github.com/6C656C65/ansible_roles/tree/main/proxmox)

---