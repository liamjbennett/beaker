require 'spec_helper'

class ClassMixedWithDSLWrappers
  include Beaker::DSL::Wrappers
end

describe ClassMixedWithDSLWrappers do
  let(:opts)       { {'ENV' => { :HOME => "/"}, :cmdexe => true } }
  let(:empty_opts) { {'ENV' => {}, :cmdexe => true } }

  describe '#facter' do
    it 'should split out the options and pass "facter" as first arg to Command' do
      Beaker::Command.should_receive( :new ).
        with('facter', [ '-p' ], empty_opts)
      subject.facter( '-p' )
    end
  end

  describe '#cfacter' do
    it 'should split out the options and pass "cfacter" as first arg to Command' do
      Beaker::Command.should_receive( :new ).
        with('cfacter', [ '-p' ], opts)
      subject.cfacter( '-p' )
    end
  end

  describe '#hiera' do
    it 'should split out the options and pass "hiera" as first arg to Command' do
      Beaker::Command.should_receive( :new ).
        with('hiera', [ '-p' ], empty_opts)
      subject.hiera( '-p')
    end
  end

  describe '#puppet' do
    it 'should split out the options and pass "puppet <blank>" to Command' do
      merged_opts = opts
      merged_opts[:server] = 'master'
      Beaker::Command.should_receive( :new ).
        with('puppet agent', [ '-tv' ], merged_opts)
      subject.puppet( 'agent', '-tv', :server => 'master', 'ENV' => {:HOME => '/'})
    end
  end

  describe '#host_command' do
    it 'delegates to HostCommand.new' do
      Beaker::HostCommand.should_receive( :new ).with( 'blah' )
      subject.host_command( 'blah' )
    end
  end

  describe 'deprecated puppet wrappers' do
    %w( resource doc kick cert apply master agent filebucket ).each do |sub|
      it "#{sub} delegates the proper info to #puppet" do
        subject.should_receive( :puppet ).with( sub, 'blah' )
        subject.send( "puppet_#{sub}", 'blah')
      end
    end
  end

  describe '#powershell' do
    it 'should pass "powershell.exe <args> -Command <command>" to Command' do
      command = subject.powershell("Set-Content -path 'fu.txt' -value 'fu'")
      command.command.should == 'powershell.exe'
      command.args.should == ' -ExecutionPolicy Bypass -InputFormat None -NoLogo -NoProfile -NonInteractive -Command "Set-Content -path \'fu.txt\' -value \'fu\'"'
      command.options.should == {}
    end

    it 'should merge the arguments provided with the defaults' do
      command = subject.powershell("Set-Content -path 'fu.txt' -value 'fu'", {'ExecutionPolicy' => 'Unrestricted'})
      command.command.should == 'powershell.exe'
      command.args.should == ' -ExecutionPolicy Unrestricted -InputFormat None -NoLogo -NoProfile -NonInteractive -Command "Set-Content -path \'fu.txt\' -value \'fu\'"'
      command.options.should == {}
    end
  end
end
