

function dc() {
  if [[ $@ == "ls" ]]; then
    command docker container ls -a ;
  else
    command docker container $@ ;
  fi
}


function dcr() {
  if [[ $# -eq 0 ]]; then
    command docker rm $(docker ps -a -f status=exited -q) ;
  else
    command docker rm $@ ;
  fi
}
function dir() {
  docker rmi $(docker images -a -q)
}
# リンク切れのVolumeを削除
alias dvr='docker volume ls -qf dangling=true | xargs -r docker volume rm'
alias dl='docker container ls -a'
alias d='docker'
alias dv='docker volume $@'
alias di='docker images $@'
alias d-c='docker-compose'
