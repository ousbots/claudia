# Starts a docker container for running claude with the current directory as the workspace.
function claudy
    sandbox-exec -f $HOME/work/claude/sandbox-profile.sb -D HOME=$HOME -D WORK_DIR=$(pwd) claude
end
