OUTDIR=../www
SYNCDIR=

process.timestamp: *.html templates/*.html static/* static/styles/* static/javascript/* Makefile process.rb
	@mkdir -p $(OUTDIR); \
	ruby process.rb *.html -s static/ -f -o $(OUTDIR); \
	if [ ! -z "$(SYNCDIR)" ]; then \
		echo "Copying $(OUTDIR) to $(SYNCDIR)..."; \
		rm -rf $(SYNCDIR) && cp -r $(OUTDIR) $(SYNCDIR); \
	fi; \
	touch process.timestamp;

all: process.timestamp
