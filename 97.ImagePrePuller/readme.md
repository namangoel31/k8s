# IMPORTANT THEORY

## hostPID: true
"hostPID: true" is not always required for an image pre-puller. Infact, its required for debugging and monitoring nodes at process-level.
For our puller, We’re only talking to containerd’s socket (/run/containerd/containerd.sock) to pull images.
We don’t need to see or interact with host PIDs. The only hostPath we need is the containerd socket.

WE CAN SAFELY DROP "hostPID: true" from our manifest file.

## securityComtext: priveleged: true
Now, we have 
securityContext:
  privileged: true

definitely more power than we need.

### What capabilities do we need for image pulling?
When we mount /run/containerd/containerd.sock into the pod, the binary (ctr or crictl) is just making gRPC calls to containerd — no special kernel-level privileges are needed beyond:
1. Being able to read/write that socket file
2. Having network access for pulling layers from registry

The read/write on the socket comes from:
1. Pod’s UID/GID matching the owner of the socket (containerd socket usually root:root with 0660 perms)
2. Or giving the container CAP_DAC_OVERRIDE and CAP_DAC_READ_SEARCH to bypass file permissions

so instead of "privileged: true", we can do

securityContext:
  runAsUser: 0
  runAsGroup: 0
  capabilities:
    drop: ["ALL"]
    add:
      - DAC_OVERRIDE
      - DAC_READ_SEARCH

#### What does what?
1. runAsUser: 0 -> root
2. runAsGroup: 0 -> root
3. drop: ["ALL"] -> drops all other capabilities for least privilege
4. DAC_OVERRIDE -> bypasses file permission checks
5. DAC_READ_SEARC -> bypass directory search perms

#### Let's talk about DAC_OVERRIDE
DAC (Discretionary Access Control) override is a process capability that allows root to bypass file read, write, and execute permission checks. This means that a root capable process can read, write, and execute any file on the system, even if the permission and ownership fields would not allow it.

SEEMS A BIT TOO BROAD!! LETS GO TIGHTER..

## avoid CAP_DAC_OVERRIDE completely

### Hot to?
1. Run as root inside container (just for socket access)
2. Ensure containerd socket is group-readable and mount that group into the pod

#### If node is directly accessible, run:
ls -l /run/containerd/containerd.sock

output should be something like 
srw-rw----  1 root       root           0 Aug  2 07:00 /run/containerd/containerd.sock
or
srw-rw----  1 root       containerd         0 Aug  2 08:30 /run/containerd/containerd.sock

If it’s root:root, Running pod as root inside will work without extra capabilities.
If it’s root:containerd (or similar group), You can runAsGroup with that GID instead of adding capabilities.

#### If you can't acces node:
Check the socket permissions by running a debug pod on that node with /run/containerd/containerd.sock mounted

exec into the pod and run
ls -l /run/containerd/containerd.sock

output should be something like 
srw-rw----    1 root     root             0 Jul  6 08:32 /run/containerd/containerd.sock
or
srw-rw----    1 root     containerd       0 Aug  2 08:39 /run/containerd/containerd.sock

Decide the right securityContext
If root root → runAsUser: 0, runAsGroup: 0, drop all capabilities
If root containerd → runAsUser: 0, runAsGroup: <gid of containerd>, drop all capabilities

You can get the GID by running:
stat -c '%u %g %A' /run/containerd/containerd.sock


Now, we can get get rid of all elevated permissions and just

securityContext:
  runAsUser: 0
  runAsGroup: 0
  capabilities:
    drop: ["ALL"]