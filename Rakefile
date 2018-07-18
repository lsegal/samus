task default: :build

task :build do
  home = Dir.home
  id = `docker build -q .`.chomp
  dirs = [
    "#{home}/.ssh:/root/.sshkeys",
    "#{home}/.samus:/root/.samus",
    "#{home}/.gitconfig:/root/.gitconfig",
    "#{Dir.pwd}:/app"
  ]
  cmd = "rake build_from_docker VERSION=#{ENV['VERSION']}"
  alldirs = dirs.map { |d| "-v \"#{d}\"" }.join(' ')
  sh "docker run --rm #{alldirs} -w /app -t #{id} #{cmd}"
end

task :build_from_docker do
  version = ENV['VERSION']
  sh 'mkdir -p ~/.ssh && cp -R ~/.sshkeys/* ~/.ssh'
  sh 'chmod 700 ~/.ssh && chmod 400 ~/.ssh/*'
  sh "samus build #{version}"
end

task :publish do
  home = Dir.home
  id = `docker build -q .`.chomp
  dirs = [
    "#{home}/.ssh:/root/.sshkeys",
    "#{home}/.samus:/root/.samus",
    "#{home}/.gitconfig:/root/.gitconfig",
    "#{Dir.pwd}:/app"
  ]
  cmd = "rake publish_from_docker FILE=#{ENV['FILE']}"
  alldirs = dirs.map { |d| "-v \"#{d}\"" }.join(' ')
  sh "docker run --rm #{alldirs} -w /app -t #{id} #{cmd}"
end

task :publish_from_docker do
  file = ENV['FILE']
  sh 'mkdir -p ~/.ssh && cp -R ~/.sshkeys/* ~/.ssh'
  sh 'chmod 700 ~/.ssh && chmod 400 ~/.ssh/*'
  sh "samus publish #{file}"
end
