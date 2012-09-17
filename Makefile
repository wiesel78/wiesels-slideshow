all : prog man


prog : gslideshow.pl
	cp gslideshow.pl gslideshow

man : gslideshow.1
	gzip gslideshow.1

install : gslideshow gslideshow.1.gz
	cp gslideshow.1.gz /usr/share/man/man1/gslideshow.1.gz
	cp gslideshow /usr/bin/gslideshow

clean : 
	rm gslideshow
	gzip -d gslideshow.1.gz
