#!/usr/bin/env bash
# The first part of this script is inspired by
# https://gist.github.com/mbbx6spp/4f467adb4e0133063fd87e264c6b9f78
# and the second part by
# https://github.com/pjotrp/guix-notes/blob/master/GUIX-NO-ROOT.org
set -eu

# The path to your local binary folder
BINDIR="${HOME}/opt/bin"
# Where to install the nix that needs proot to work
NIXPROOT="${HOME}/nixproot"
# Choose which version to install. You can get the last
# version from https://nixos.org/nix/manual/
NIXVER="1.11.15"
# Arch of the host
ARCH="x86_64"
# Os
OS="linux"




############################################
#####  Install the proot version of nix ####
############################################

function install_nixproot() {
    echo "########## INSTALLING NIX UNDER PROOT ##########"
    nixbz2_url="http://nixos.org/releases/nix/nix-${NIXVER}/nix-${NIXVER}-${ARCH}-${OS}.tar.bz2"
    proot_url="https://github.com/proot-me/proot-static-build/raw/master/static/proot-${ARCH}"

    echo "=== Installing proot..."
    # Download proot
    mkdir -p "${BINDIR}"
    wget -O "${BINDIR}/proot" "${proot_url}"
    chmod u+x "${BINDIR}/proot"

    echo "=== Downloading proot..."
    # Download nix
    mkdir -p "${NIXPROOT}"
    pushd "${NIXPROOT}"
    wget "${nixbz2_url}"
    tar xjf nix-*bz2
    
    echo "=== Creating easy to use scripts..."
    export PATH="${BINDIR}:${PATH}"
    {
	echo "#!/usr/bin/env bash"
	echo
	echo "PROOT_NO_SECCOMP=1 proot -b \"${NIXPROOT}/nix-${NIXVER}-${ARCH}-${OS}/:/nix\" \$@"
    } > "${BINDIR}/nixproot-onecommand"
    chmod u+x "${BINDIR}/nixproot-onecommand"
    {
	echo "#!/usr/bin/env bash"
	echo
	echo "PROOT_NO_SECCOMP=1 proot -b \"${NIXPROOT}/nix-${NIXVER}-${ARCH}-${OS}/:/nix\" bash --init-file <(echo -e \".  \${HOME}/.nix-profile/etc/profile.d/nix.sh\necho \\\"Welcome in proot nix, you can run here any proot command, and run programs.\\\"\\necho \\\"But beware, it can be quite slow\\\"\nPS1=\\\"nix-proot:$ \\\"\")"
    } > "${BINDIR}/nixproot-bash"
    chmod u+x "${BINDIR}/nixproot-bash"
    ${BINDIR}/nixproot-onecommand /nix/install
    echo "Done !"
    echo ""
    echo "Now, if you want to run an application in nix, first make sure"
    echo "that you have a line like this in your .bashrc:"
    echo "export PATH=\"${BINDIR}:\${PATH}\""
    echo "And then run"
    echo "nixproot-bash"
    echo "Then, you will be in a shell under proot, where you can run any nix command, like"
    echo "nix-env -qa"
    echo "But because of the proot overhead, it can be quite slow..."
}

function uninstall_nixproot() {
    rm -rf "${BINDIR}/nixproot-onecommand"
    rm -rf "${BINDIR}/nixproot-bash"
    rm -rf "${BINDIR}/proot"
    chmod 644 -R "${NIXPROOT}"
    rm -rf "${NIXPROOT}"
}

install_nixproot
# uninstall_nixproot
# delta
