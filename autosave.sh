#!/bin/bash

cd /cloudheim

dir="/valheim/backups"
world="rip_hermeto"

# Valheim 1.0 stores a world as a directory (worlds_local/<world>/ holding
# _main.<gen>.fwl2 metadata, _main.<gen>.db2 data, _main.<gen>.chunks, and a
# _main.<gen>.ok marker written when a save completes). Pre-1.0 worlds were
# a <world>.db/.fwl file pair. Handle both.

commit_world() {
  git config user.name >/dev/null 2>&1 || git config user.name "cloudheim-autosave"
  git config user.email >/dev/null 2>&1 || git config user.email "autosave@cloudheim.local"
  git add "$world"
  if ! git diff --cached --quiet; then
    git commit -m "AUTO: Autosave"
    git push
  else
    echo "No world changes since the last autosave."
  fi
}

unset -v latest
for file in "$dir"/*.tar.gz; do
  [[ $file -nt $latest ]] && latest=$file
done

echo "$latest"

# Unpack the newest backup tarball and commit the world files inside it
if [ -f "$latest" ]; then
  scratch=$(mktemp -d)
  tar -xzf "$latest" -C "$scratch"

  if [ -d "$scratch/worlds_local/$world" ]; then
    # 1.0 format: only ship saves that actually completed. The game writes
    # a _main.<gen>.ok file when a save finishes; with no .ok the world has
    # not been saved yet (nothing to preserve).
    if compgen -G "$scratch/worlds_local/$world/_main.*.ok" >/dev/null; then
      rm -rf "$world/worlds_local/$world"
      mkdir -p "$world/worlds_local"
      cp -rf "$scratch/worlds_local/$world" "$world/worlds_local/$world"
      commit_world
    else
      echo "No completed 1.0 save (_main.*.ok) in $latest; skipping."
    fi
  elif [ -f "$scratch/worlds_local/$world.db" ] && [ -f "$scratch/worlds_local/$world.fwl" ]; then
    # Pre-1.0 format fallback
    mkdir -p "$world/worlds_local"
    cp -f "$scratch/worlds_local/$world.db" "$world/worlds_local/$world.db"
    cp -f "$scratch/worlds_local/$world.fwl" "$world/worlds_local/$world.fwl"
    commit_world
  else
    echo "No $world directory or db/fwl pair found in $latest; skipping."
  fi

  rm -rf "$scratch"
fi
