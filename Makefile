process.timestamp: *.html templates/*.html Makefile
	ruby process.rb *.html -s static/ -f;
	@rm -rf $(HOME)/public_html/codyn && cp -r generated $(HOME)/public_html/codyn;
	@touch process.timestamp

all: process.timestamp
