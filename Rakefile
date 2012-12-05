ROOT = File.dirname __FILE__

task :default => :build

desc "Run automated tests."
task :test => ['node_modules/.bin/coffee', :build] do
    sh "bin/runtests"
end

build_deps = [
    'dist',
    'dist/node_modules',
    'dist/capsulate.js',
    'dist/package.json',
    'dist/README.md',
    'dist/MIT-LICENSE'
]
desc "Build JavaScript files."
task :build => build_deps do
    puts "build done ..."
end

desc "Install development dependencies."
file 'node_modules/.bin/coffee' => 'package.json' do
    # sh "npm install --dev" Results in infinte loop
    sh "sudo npm install"
end

directory 'dist'

file 'dist/node_modules' => 'dist/package.json' do
    Dir.chdir 'dist'
    sh "npm install --production"
    Dir.chdir ROOT
end

file 'dist/package.json' => ['package.json', 'dist'] do |task|
    FileUtils.cp task.prerequisites.first, task.name
end

file 'dist/README.md' => ['README.md', 'dist'] do |task|
    FileUtils.cp task.prerequisites.first, task.name
end

file 'dist/MIT-LICENSE' => ['MIT-LICENSE', 'dist'] do |task|
    FileUtils.cp task.prerequisites.first, task.name
end

file 'dist/capsulate.js' => ['capsulate.coffee', 'dist'] do |task|
    brew_javascript(task.prerequisites.first, task.name)
end

desc "Start over with a clean slate."
task :clean do
    rm_rf 'node_modules'
    rm_rf 'dist'
end

def brew_javascript(source, target, node_exec=false)
    File.open(target, 'w') do |fd|
        if node_exec
            fd << "#!/usr/bin/env node\n\n"
        end
        fd << %x[node_modules/coffee-script/bin/coffee -pb #{source}]
    end
end
