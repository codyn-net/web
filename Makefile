OUTDIR=generated
SYNCDIR=$(HOME)/public_html/codyn

process.timestamp: *.html templates/*.html static/* static/styles/* static/javascript/* Makefile process.rb
	@mkdir -p $(OUTDIR); \
	ruby process.rb *.html -s static/ -f -o $(OUTDIR) || exit 1; \
	if [ ! -z "$(SYNCDIR)" ]; then \
		echo "Copying $(OUTDIR) to $(SYNCDIR)..."; \
		rm -rf $(SYNCDIR) && cp -r $(OUTDIR) $(SYNCDIR) || exit 1; \
	fi; \
	touch process.timestamp;

all: process.timestamp
