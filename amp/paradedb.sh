#!/bin/sh

# create paradedb skill dir
mkdir -p ~/.config/agents/skills/paradedb-skill
# install skill
curl -o ~/.config/agents/skills/paradedb-skill/SKILL.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/SKILL.md
# install examples
curl -o ~/.config/agents/skills/paradedb-skill/EXAMPLES.md \
  https://raw.githubusercontent.com/paradedb/agent-skills/main/EXAMPLES.md
