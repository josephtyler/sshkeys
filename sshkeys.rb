#!/usr/bin/ruby

require 'rubygems'

def require_or_fail(lib)
  begin
    require lib
  rescue LoadError
    puts "Required gem missing: #{lib}"
    exit false
  end
end

require_or_fail('etc')
require_or_fail('net/ssh')
require_or_fail('net/scp')

# See if id_rsa.pub exists
unless File.exist? "#{ENV["HOME"]}/.ssh/id_rsa.pub"
  puts "To use this tool, the file id_rsa.pub must exist in \
      #{ENV["HOME"]}/.ssh/. Trying running `ssh-keygen -t rsa`."
  exit
end

idrsa_file = "#{ENV["HOME"]}/.ssh/id_rsa.pub"

host = ''
while host == ''
  print 'Enter the host or IP address to which you will ssh: '
  host = gets.chomp
end

username = ''
while username == ''
  print "Enter your username for #{host}: "
  username = gets.chomp
end

password = ''
while password == ''
  print "Enter your password for #{username}@#{host}: "
  password = gets.chomp
end

# Create the remote folder
Net::SSH.start(host, username, :password => password) do |ssh|
  puts '> creating remote .ssh folder'
  ssh.exec! 'mkdir ~/.ssh'
end

# SCP the id_rsa.pub file to remote machine
Net::SCP.start(host, username, :password => password) do |scp|
  puts '> scp started'
  scp.upload! idrsa_file, ".ssh/"
end

# Add the id_rsa.pub to the authorized_keys
Net::SSH.start(host, username, :password => password) do |ssh|
  puts '> creating authorized_keys and adding your key'
  ssh.exec! 'touch ~/.ssh/authorized_keys'
  ssh.exec! 'chmod 600 ~/.ssh/authorized_keys'
  ssh.exec! 'chmod 700 ~/.ssh'
  ssh.exec! 'cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys'
end
