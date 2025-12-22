# Starts a docker container for running claude with the current directory as the workspace.
function claudy
    if contains -- --rebuild $argv
        docker compose -f ~/work/claude/docker-compose.yaml build --no-cache
        docker compose -f ~/work/claude/docker-compose.yaml run --volume $(pwd):/home/timo/workspace/$(pwd | cut -d'/' -f4-):rw --workdir /home/timo/workspace/$(pwd | cut -d'/' -f4-) --rm claude
    else
        docker compose -f ~/work/claude/docker-compose.yaml run --volume $(pwd):/home/timo/workspace/$(pwd | cut -d'/' -f4-):rw --workdir /home/timo/workspace/$(pwd | cut -d'/' -f4-) --rm claude
    end
end
