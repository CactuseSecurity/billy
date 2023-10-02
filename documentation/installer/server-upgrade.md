# Upgrade instructions

It is really simple.

If you already have a local git repository from the original installation:

```console
  cd billy
  git pull                                                          # to upgrade the repo from the original repo@github
  ansible-playbook site.yml -K -e "installation_mode=upgrade"
```

If you do not have a local repo:

```console
  git clone https://github.com/cactusesecurity/billy
  cd billy
  ansible-playbook site.yml -K -e "installation_mode=upgrade"
```
