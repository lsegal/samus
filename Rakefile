require_relative './lib/samus'

task default: 'samus:build'

Samus::Rake::DockerReleaseTask.new

task :images do
  sh "docker build -t lsegal/samus:latest -f Dockerfile ."
  sh "docker build -t lsegal/samus:build -f Dockerfile.build ."
end

namespace :samus do
  task build: :images
end
