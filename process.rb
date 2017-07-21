#!/usr/bin/ruby

require 'erb'
require 'optparse'
require 'fileutils'
require 'rubygems'
require 'kramdown'
require 'coderay'
require 'cgi'
require 'json'
require 'net/http'

module CodeRay
module Scanners
    class Codyn < Scanner
        register_for :codyn
        file_extension 'cdn'

        KEYWORDS = [
            'action',
            'all',
            'any',
            'apply',
            'as',
            'at',
            'bidirectional',
            'context',
            'debug-print',
            'defines',
            'delete',
            'edge',
            'event',
            'from',
            'functions',
            'import',
            'in',
            'include',
            'integrated',
            'integrator',
            'interface',
            'io',
            'layout',
            'link-library',
            'node',
            'no-self',
            'object',
            'of',
            'on',
            'once',
            'out',
            'parse',
            'phase',
            'piece',
            'polynomial',
            'probability',
            'require',
            'set',
            'settings',
            'terminate',
            'templates',
            'to',
            'unapply',
            'when',
            'with',
            'within'
        ]

        SELECTORS = [
            'actions',
            'append-context',
            'applied-templates',
            'children',
            'count',
            'debug',
            'edges',
            'first',
            'from-set',
            'has-flag',
            'has-template',
            'if',
            'ifstr',
            'imports',
            'input',
            'input-name',
            'inputs',
            'last',
            'name',
            'nodes',
            'not',
            'notstr',
            'objects',
            'output',
            'output-name',
            'outputs',
            'parent',
            'recurse',
            'reduce',
            'reverse',
            'root',
            'self',
            'siblings',
            'subset',
            'templates-root',
            'type',
            'unique',
            'variables'
        ]

        IDENT_KIND = WordList.new(:ident).
            add(KEYWORDS, :keyword).
            add(SELECTORS, :selector)

        protected
            def scan_tokens encoder, options
                state = :initial

                until eos?
                    case state
                    when :initial
                        if match = scan(/\# .* /x)
                            encoder.text_token(match, :comment)
                        elsif match = scan(/ [A-Za-z_][A-Za-z_0-9]* /x)
                            kind = IDENT_KIND[match]

                            if kind != false
                                encoder.text_token(match, kind)
                            else
                                encoder.text_token(match, :identifier)
                            end
                        elsif match = scan(/ " /x)
                            encoder.begin_group(:string)
                            encoder.text_token(match, :plain)
                            state = :string
                        else
                            encoder.text_token(getch, :plain)
                        end
                    when :string
                        if match = scan(/ [^\\\n"]+ /x)
                            encoder.text_token(match, :plain)
                        elsif match = scan(/ " /x)
                            encoder.text_token(match, :plain)
                            encoder.end_group(:string)
                            state = :initial
                        else
                            encoder.text_token(getch, :plain)
                    end
                end
            end

            if state == :string
                encoder.end_group(:string)
            end

            encoder
        end
    end
end
end

class Context
    attr_reader :vars

    def initialize(vars = {})
        @vars = vars

        @vars.each do |key, value|
            instance_variable_set("@#{key}", value)

            metaclass = class << self; self; end

            metaclass.class_eval do
                attr_reader key.to_sym
            end
        end
    end

    def var(name, defval = nil)
        instance_variable_get("@#{name}") or defval
    end

    def context
        binding
    end

    def merge(vars = {})
        Context.new(@vars.merge(vars))
    end

    def template(filename, vars = {}, &block)
        templ = ERB.new(File.read(filename), nil, nil, '@_erout')

        if block_given?
            before = @_erout.length

            ret = yield

            after = @_erout.length

            vars[:contents] = @_erout[before..after]
            @_erout[before..after] = ''

            return @engine.context(vars) do |ctx|
                @_erout += templ.result(ctx.context)
            end
        end

        return @engine.context(vars) do |ctx|
            templ.result(ctx.context)
        end
    end

    def image(filename, caption)
        caption = CGI.escapeHTML(caption)

        @_erout += "<div class='image-container'>\n"
        @_erout += "<div class='image'>\n"
        @_erout += "<img src='images/#{CGI.escapeHTML(filename)}' alt='#{caption}'>\n"
        @_erout += "<div class='caption'>#{caption}</div>\n"
        @_erout += "</div>\n"
        @_erout += "</div>\n"
    end

    def simulation_data(filename, varname)
        data = File.read('gallery/' + filename).split("\n").map { |x| x.split(" ").map { |d| d.to_f } }

        @_erout += "<script type='text/javascript'>\n"
        @_erout += "  var #{varname} = " + data.to_json + ";\n"
        @_erout += "</script>\n"
    end

    def markdown
        before = @_erout.length

        ret = yield

        after = @_erout.length

        opts = {
            :coderay_css => :class,
            :coderay_default_lang => 'text',
            :toc_levels => "1,2",
            :coderay_line_numbers => :table,
        }

        @_erout[before..after] = Kramdown::Document.new(@_erout[before..after], opts).to_html
    end

    def input(filename, opts = {})
        ret = File.read(filename)

        if opts[:strip]
            ret.strip!
        end

        return ret
    end

    def input_model(filename)
        ret = input(filename, {:strip => true})
        play = playground_put(ret)

        markdown do
            @_erout += "~~~~ codyn\n#{ret}\n~~~~\n"
            @_erout += "[⌦ Open in playground](https://play.codyn.net/d/#{play})"
        end
    end

    def playground_put(txt)
        http = Net::HTTP.new('play.codyn.net', 80)
        response = http.send_request('PUT', '/d/', "document=#{CGI.escape(txt)}")

        ret = JSON.parse(response.body)
        return ret['hash']
    end
end

class Engine
    def self.run(files, outputdir, vars = {})
        FileUtils.mkdir_p(outputdir)

        files.each do |f|
            engine = Engine.new(f, outputdir)
            engine.process(vars)
        end
    end

    def initialize(filename, outputdir)
        @filename = filename
        @outputdir = outputdir
        @vars = {}
        @contexts = []
    end

    def current_context
        @contexts.last
    end

    def push_context(vars = {})
        if @contexts.empty?
            @contexts << Context.new(vars)
        else
            @contexts << current_context.merge(vars)
        end

        current_context
    end

    def pop_context
        @contexts.delete_at(@contexts.length - 1) unless @contexts.empty?
    end

    def context(vars = {})
        ctx = push_context(vars)

        ret = yield ctx

        pop_context

        return ret
    end

    def process(vars)
        ret = context(vars.merge({:engine => self})) do |ctx|
            ctx.template(@filename)
        end

        # Write it
        outfile = File.join(@outputdir, @filename)
        FileUtils.mkdir_p(File.dirname(outfile))

        File.new(outfile, 'w').write(ret)
    end
end

$options = {:output => 'generated', :static => [], :force => false}

OptionParser.new do |opts|
    opts.banner = "Usage: process.rb [$options] FILES"

    opts.on("-o DIR", "--output DIR", "Output directory") do |o|
        $options[:output] = o
    end

    opts.on("-s FILE", "--static FILE", "Static files to copy") do |s|
        $options[:static] << s
    end

    opts.on("-f", "--force", "Force overriding existing files") do
        $options[:force] = true
    end
end.parse!

exist = File.exist?($options[:output])

if exist and not $options[:force]
    STDOUT.write("The output directory `#{$options[:output]}' already exists, remove? [y]es/[c]ancel: ")

    system("stty raw -echo")
    c = STDIN.getc
    system("stty -raw echo")
    STDOUT.puts

    case c
        when ?c
            exit 1
    end
end

if exist
    FileUtils.rm_r($options[:output])
end

Engine.run(ARGV, $options[:output])

def link(filename, dest)
    return if ['..', '.'].include?(File.basename(filename))

    FileUtils.mkdir_p(dest)

    if File.directory?(filename)
        if not filename.end_with?('/')
            dest = File.join(dest, File.basename(filename))
            FileUtils.mkdir_p(dest)
        end

        Dir.entries(filename).each do |entry|
            link(File.join(filename, entry), dest)
        end
    else
        destfile = File.join(dest, File.basename(filename))

        exist = File.exist?(destfile)

        if exist and not $options[:force]
            while true
                STDOUT.write("The file `#{destfile}' already exists, override? [y]es/[n]o/[a]ll/[c]ancel: ")

                system("stty raw -echo")
                c = STDIN.getc
                system("stty -raw echo")
                STDOUT.puts

                case c
                    when ?y
                        break
                    when ?n
                        return
                    when ?a
                        $options[:force] = true
                        break
                    when ?c
                        exit 1
                end
            end
        end

        if exist
            File.unlink(destfile)
        end

        FileUtils.ln(filename, dest)
    end
end

# Copy static files
$options[:static].each do |item|
    link(item, $options[:output])
end

# vi:ex:ts=4:et
