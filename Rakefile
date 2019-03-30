task default: :build

def docker_cmd
  "docker run --rm -v #{Dir.home}:/root:ro -v #{Dir.pwd}:/build lsegal/samus"
end

task :image do
  sh "docker build -t lsegal/samus ."
end

task build: :image do
  sh "#{docker_cmd} build #{ENV['VERSION']}"
end

task :publish do
  sh "#{docker_cmd} publish release-v#{ENV['VERSION']}.tar.gz"
end
