DIR ?= dir
MALICIOUS_DIR ?= malicious_dir
INTERVAL ?= 5

.PHONY: all setup run restore clean

all: run

setup:
	mkdir -p $(MALICIOUS_DIR) $(DIR)
	chmod +x antivirusd.sh restore.sh antivirus-cron.sh

run: setup
	./antivirusd.sh $(DIR) $(MALICIOUS_DIR) $(INTERVAL)

restore: setup
	./restore.sh $(DIR) $(MALICIOUS_DIR)

clean:
	rm -f directory-info.last directory-info.new
