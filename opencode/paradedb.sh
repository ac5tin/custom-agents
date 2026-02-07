#!/bin/sh

# create paradedb skill dir
mkdir -p ~/.config/opencode/skill/paradedb-skill
# install skill
curl -o ~/.config/opencode/skill/paradedb-skill/SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
# install examples
curl -o ~/.config/opencode/skill/paradedb-skill/EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
