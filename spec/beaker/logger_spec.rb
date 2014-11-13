# encoding: UTF-8
require 'spec_helper'

module Beaker
  describe Logger, :use_fakefs => true do
    let(:my_io)  { MockIO.new                         }
    let(:logger) { Logger.new(my_io, :quiet => true)  }


    context '#convert' do
      let(:valid_utf8)  { "/etc/puppet/modules\n├── jimmy-appleseed (\e[0;36mv1.1.0\e[0m)\n├── jimmy-crakorn (\e[0;36mv0.4.0\e[0m)\n└── jimmy-thelock (\e[0;36mv1.0.0\e[0m)\n" }
      let(:invalid_utf8) {"/etc/puppet/modules\n├── jimmy-appleseed (\e[0;36mv1.1.0\e[0m)\n├── jimmy-crakorn (\e[0;36mv0.4.0\e[0m)\n└── jimmy-thelock (\e[0;36mv1.0.0\e[0m)\xAD\n"}

      it 'preserves valid utf-8 strings' do
        expect( logger.convert(valid_utf8) ).to be === valid_utf8
      end
      it 'strips out invalid utf-8 characters' do
        #this is 1.9 behavior only
        if RUBY_VERSION.to_f >= 1.9
          expect( logger.convert(invalid_utf8) ).to be === valid_utf8
        else
          pending "not supported in ruby 1.8 (using #{RUBY_VERSION})"
        end
      end
    end

    context 'new' do
      it 'does not duplicate STDOUT when directly passed to it' do
        stdout_logger = Logger.new STDOUT
        expect( stdout_logger ).to have(1).destinations
      end


      context 'default for' do
        its(:destinations)  { should include(STDOUT)  }
        its(:color)         { should be_nil           }
        its(:log_level)     { should be :verbose      }
      end
    end


    context 'it can' do
      it 'open/create a file when a string is given to add_destination' do
        logger.add_destination 'my_tmp_file'
        expect( File.exists?( 'my_tmp_file' ) ).to be_true

        io = logger.destinations.select {|d| d.respond_to? :path }.first
        expect( io.path ).to match /my_tmp_file/
      end

      it 'remove destinations with the remove_destinations method' do
        logger.add_destination 'my_file'

        logger.remove_destination my_io
        logger.remove_destination 'my_file'

        expect( logger.destinations ).to be_empty
      end

      it 'strip colors from arrays of input' do
        stripped = logger.strip_colors_from [ "\e[00;30m text! \e[00;00m" ]
        expect( stripped ).to be === [ ' text! ' ]
      end

      it 'colors strings if @color is set' do
        colorized_logger = Logger.new my_io, :color => true, :quiet => true

        my_io.should_receive( :print ).with "\e[00;30m"
        my_io.should_receive( :print )
        my_io.should_receive( :puts ).with 'my string'

        colorized_logger.optionally_color "\e[00;30m", 'my string'
      end

      context 'at trace log_level' do
        subject( :trace_logger )  { Logger.new( my_io,
                                              :log_level => 'trace',
                                              :quiet => true,
                                              :color => true )
                                  }

        its( :is_debug? ) { should be_true }
        its( :is_trace? ) { should be_true }
        its( :is_warn? )  { should be_true }

        context 'but print' do
          before do
            my_io.stub :puts
            my_io.should_receive( :print ).at_least :twice
          end

          it( 'warnings' )    { trace_logger.warn 'IMA WARNING!'    }
          it( 'successes' )   { trace_logger.success 'SUCCESS!'     }
          it( 'errors' )      { trace_logger.error 'ERROR!'         }
          it( 'host_output' ) { trace_logger.host_output 'ERROR!'   }
          it( 'debugs' )      { trace_logger.debug 'DEBUGGING!'     }
          it( 'traces' )      { trace_logger.trace 'TRACING!'       }
        end
      end

      context 'at verbose log_level' do
        subject( :verbose_logger )  { Logger.new( my_io,
                                              :log_level => 'verbose',
                                              :quiet => true,
                                              :color => true )
                                  }

        its( :is_trace? ) { should be_false }
        its( :is_debug? ) { should be_false }
        its( :is_verbose? ) { should be_true }
        its( :is_warn? )  { should be_true }

        context 'but print' do
          before do
            my_io.stub :puts
            my_io.should_receive( :print ).at_least :twice
          end

          it( 'warnings' )    { verbose_logger.warn 'IMA WARNING!'    }
          it( 'successes' )   { verbose_logger.success 'SUCCESS!'     }
          it( 'errors' )      { verbose_logger.error 'ERROR!'         }
          it( 'host_output' ) { verbose_logger.host_output 'ERROR!'   }
          it( 'debugs' )      { verbose_logger.debug 'NOT DEBUGGING!' }
        end
      end

      context 'at debug log_level' do
        subject( :debug_logger )  { Logger.new( my_io,
                                              :log_level => 'debug',
                                              :quiet => true,
                                              :color => true )
                                  }

        its( :is_trace? ) { should be_false }
        its( :is_debug? ) { should be_true }
        its( :is_warn? )  { should be_true }

        context 'successfully print' do
          before do
            my_io.stub :puts
            my_io.should_receive( :print ).at_least :twice
          end

          it( 'warnings' )    { debug_logger.warn 'IMA WARNING!'        }
          it( 'debugs' )      { debug_logger.debug 'IMA DEBUGGING!'     }
          it( 'successes' )   { debug_logger.success 'SUCCESS!'         }
          it( 'errors' )      { debug_logger.error 'ERROR!'             }
          it( 'host_output' ) { debug_logger.host_output 'ERROR!'       }
        end
      end

      context 'at info log_level' do
        subject( :info_logger ) { Logger.new( my_io,
                                              :log_level => :info,
                                              :quiet     => true,
                                              :color     => true )
                                  }

        its( :is_debug? ) { should be_false }
        its( :is_trace? ) { should be_false }


        context 'skip' do
          before do
            my_io.should_not_receive :puts
            my_io.should_not_receive :print
          end

          it( 'debugs' )    { info_logger.debug 'NOT DEBUGGING!' }
          it( 'traces' )    { info_logger.debug 'NOT TRACING!'   }
        end


        context 'but print' do
          before do
            my_io.should_receive :puts
            my_io.should_receive( :print ).twice
          end

          it( 'successes' )     { info_logger.success 'SUCCESS!'  }
          it( 'notifications' ) { info_logger.notify 'NOTFIY!'    }
          it( 'errors' )        { info_logger.error 'ERROR!'      }
        end
      end
    end
  end
end
